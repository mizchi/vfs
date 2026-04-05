///|
pub struct S3Fs {
  client : @s3client.S3Client
  prefix : String
}

///|
pub fn S3Fs::new(client : @s3client.S3Client, prefix? : String = "") -> S3Fs {
  { client, prefix }
}

// --- Helpers ---

///|
/// Convert a VFS path like "/foo/bar.txt" to an S3 key like "{prefix}foo/bar.txt".
fn S3Fs::to_key(self : S3Fs, path : String) -> String {
  let normalized = @path.normalize(path)
  // Strip leading "/"
  let relative = if normalized == "/" { "" } else { normalized[1:].to_string() }
  self.prefix + relative
}

///|
/// Convert a VFS path to an S3 directory key (with trailing /).
fn S3Fs::to_dir_key(self : S3Fs, path : String) -> String {
  let normalized = @path.normalize(path)
  if normalized == "/" {
    // Root maps to prefix itself (or empty)
    self.prefix
  } else {
    self.prefix + normalized[1:].to_string() + "/"
  }
}

///|
/// Split a normalized path into parts.
fn split_path(path : String) -> Array[String] {
  let normalized = @path.normalize(path)
  if normalized == "/" {
    return []
  }
  // Strip leading /
  let s = normalized[1:].to_string()
  s.split("/").map(fn(sv) { sv.to_string() }).collect()
}

// --- FileSystem trait ---

///|
pub async fn S3Fs::mkdir_p(
  self : S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let parts = split_path(path)
  // Ensure all ancestor directories as 0-byte objects with trailing /
  let mut current = ""
  for part in parts {
    current = current + part + "/"
    let key = self.prefix + current
    self.client.put_object(key, Bytes::new(0)) catch {
      e => raise @vfs.vfs_error(e.to_string())
    }
  }
}

///|
pub async fn S3Fs::write_file(
  self : S3Fs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  // Ensure parent directories exist
  let parent = @path.parent(normalized)
  if parent != "/" {
    self.mkdir_p(parent)
  }
  let key = self.to_key(normalized)
  self.client.put_object(key, content) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
}

///|
pub async fn S3Fs::write_string(
  self : S3Fs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  let bytes = @utf8.encode(content)
  self.write_file(path, bytes)
}

///|
pub async fn S3Fs::remove_file(
  self : S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let key = self.to_key(path)
  let obj = self.client.head_object(key) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
  if obj is None {
    raise @vfs.vfs_error("File not found: " + @path.normalize(path))
  }
  self.client.delete_object(key) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
}

///|
pub async fn S3Fs::remove_dir(
  self : S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let dir_key = self.to_dir_key(path)
  let objects = self.client.list_objects(dir_key) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
  for obj in objects {
    self.client.delete_object(obj.key) catch {
      e => raise @vfs.vfs_error(e.to_string())
    }
  }
  // Also delete the directory marker itself if it exists as an object
  if dir_key != "" {
    let head = self.client.head_object(dir_key) catch { _ => None }
    if head is Some(_) {
      self.client.delete_object(dir_key) catch {
        e => raise @vfs.vfs_error(e.to_string())
      }
    }
  }
}

// --- ReadableFileSystem trait ---

///|
pub async fn S3Fs::read_file(
  self : S3Fs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  let key = self.to_key(path)
  self.client.get_object(key) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
}

///|
pub async fn S3Fs::readdir(
  self : S3Fs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  let dir_key = self.to_dir_key(path)
  let objects = self.client.list_objects(dir_key) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
  let result : Array[String] = []
  let seen : Map[String, Bool] = {}
  let prefix_len = dir_key.length()
  for obj in objects {
    let key = obj.key
    if key.length() <= prefix_len {
      continue
    }
    // Get the part after the dir prefix
    let relative = key[prefix_len:].to_string()
    // Extract only the immediate child (first component)
    let child = match relative.find("/") {
      Some(idx) => relative[:idx].to_string()
      None => relative
    }
    if child != "" && !seen.contains(child) {
      seen[child] = true
      result.push(child)
    }
  }
  result
}

///|
pub async fn S3Fs::is_dir(self : S3Fs, path : String) -> Bool {
  let dir_key = self.to_dir_key(path)
  // Check if dir marker exists
  let head : @s3client.S3Object? = self.client.head_object(dir_key) catch {
    _ => None
  }
  if head is Some(_) {
    return true
  }
  // Also check if any objects exist under this prefix
  let objects : Array[@s3client.S3Object] = self.client.list_objects(dir_key) catch {
    _ => []
  }
  objects.length() > 0
}

///|
pub async fn S3Fs::is_file(self : S3Fs, path : String) -> Bool {
  let key = self.to_key(path)
  let head : @s3client.S3Object? = self.client.head_object(key) catch {
    _ => None
  }
  head is Some(_)
}

// --- Snapshottable trait ---

///|
pub async fn S3Fs::export_snapshot(self : S3Fs) -> @vfs.Snapshot {
  let objects : Array[@s3client.S3Object] = self.client.list_objects(
    self.prefix,
  ) catch {
    _ => []
  }
  let dirs : Array[String] = ["/"]
  let files : Array[@vfs.SnapshotFile] = []
  let prefix_len = self.prefix.length()
  for obj in objects {
    let key = obj.key
    if key.length() <= prefix_len {
      continue
    }
    let relative = key[prefix_len:].to_string()
    // Directory markers end with /
    if relative.length() > 0 && relative[relative.length() - 1] == '/' {
      // Convert to VFS path: strip trailing /, add leading /
      let dir_path = "/" + relative[:relative.length() - 1].to_string()
      dirs.push(dir_path)
    } else {
      // File: download the content
      let vfs_path = "/" + relative
      let data : Bytes = self.client.get_object(key) catch {
        _ => Bytes::new(0)
      }
      files.push(@vfs.snapshot_file(vfs_path, data))
    }
  }
  @vfs.snapshot(dirs, files)
}

///|
pub async fn S3Fs::replace_snapshot(
  self : S3Fs,
  snapshot : @vfs.Snapshot,
) -> Unit raise @vfs.VfsError {
  // Delete all existing objects
  let existing = self.client.list_objects(self.prefix) catch {
    e => raise @vfs.vfs_error(e.to_string())
  }
  for obj in existing {
    self.client.delete_object(obj.key) catch {
      e => raise @vfs.vfs_error(e.to_string())
    }
  }
  // Recreate directories
  for dir in snapshot.dirs {
    if dir != "/" {
      let dir_key = self.to_dir_key(dir)
      self.client.put_object(dir_key, Bytes::new(0)) catch {
        e => raise @vfs.vfs_error(e.to_string())
      }
    }
  }
  // Recreate files
  for file in snapshot.files {
    self.write_file(file.path, file.data)
  }
}

// --- Trait implementations ---

///|
impl @vfs.FileSystem for S3Fs with mkdir_p(self, path) {
  self.mkdir_p(path)
}

///|
impl @vfs.FileSystem for S3Fs with write_file(self, path, content) {
  self.write_file(path, content)
}

///|
impl @vfs.FileSystem for S3Fs with write_string(self, path, content) {
  self.write_string(path, content)
}

///|
impl @vfs.FileSystem for S3Fs with remove_file(self, path) {
  self.remove_file(path)
}

///|
impl @vfs.FileSystem for S3Fs with remove_dir(self, path) {
  self.remove_dir(path)
}

///|
impl @vfs.ReadableFileSystem for S3Fs with read_file(self, path) {
  self.read_file(path)
}

///|
impl @vfs.ReadableFileSystem for S3Fs with readdir(self, path) {
  self.readdir(path)
}

///|
impl @vfs.ReadableFileSystem for S3Fs with is_dir(self, path) {
  self.is_dir(path)
}

///|
impl @vfs.ReadableFileSystem for S3Fs with is_file(self, path) {
  self.is_file(path)
}

///|
impl @vfs.Snapshottable for S3Fs with export_snapshot(self) {
  self.export_snapshot()
}

///|
impl @vfs.Snapshottable for S3Fs with replace_snapshot(self, snapshot) {
  self.replace_snapshot(snapshot)
}
