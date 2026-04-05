///|
/// Real filesystem backend that wraps the host OS filesystem via @fs.
/// All VFS paths are resolved relative to the root directory.
pub struct RealFs {
  root : String
}

///|
pub fn RealFs::new(root : String) -> RealFs {
  { root, }
}

///|
/// Resolve a VFS path to an OS path by prepending root.
fn RealFs::resolve(self : RealFs, vfs_path : String) -> String {
  let normalized = @path.normalize(vfs_path)
  if normalized == "/" {
    self.root
  } else {
    self.root + normalized
  }
}

///|
pub async fn RealFs::mkdir_p(
  self : RealFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let resolved = self.resolve(path)
  let exists = try? @fs.exists(resolved)
  if exists is Ok(true) {
    return
  }
  @fs.mkdir(resolved, permission=0o755, recursive=true) catch {
    e => raise @vfs.vfs_error("mkdir_p failed: \{e}")
  }
}

///|
pub async fn RealFs::write_file(
  self : RealFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  let resolved = self.resolve(path)
  // Ensure parent directory exists
  let parent_vfs = @path.parent(@path.normalize(path))
  self.mkdir_p(parent_vfs) catch {
    e => raise e
  }
  @fs.write_file(resolved, content, create=0o644) catch {
    e => raise @vfs.vfs_error("write_file failed: \{e}")
  }
}

///|
pub async fn RealFs::write_string(
  self : RealFs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  let resolved = self.resolve(path)
  let parent_vfs = @path.parent(@path.normalize(path))
  self.mkdir_p(parent_vfs) catch {
    e => raise e
  }
  @fs.write_file(resolved, content, create=0o644) catch {
    e => raise @vfs.vfs_error("write_string failed: \{e}")
  }
}

///|
pub async fn RealFs::remove_file(
  self : RealFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let resolved = self.resolve(path)
  @fs.remove(resolved) catch {
    e => raise @vfs.vfs_error("remove_file failed: \{e}")
  }
}

///|
pub async fn RealFs::remove_dir(
  self : RealFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let resolved = self.resolve(path)
  @fs.rmdir(resolved, recursive=true) catch {
    e => raise @vfs.vfs_error("remove_dir failed: \{e}")
  }
}

///|
pub async fn RealFs::read_file(
  self : RealFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  let resolved = self.resolve(path)
  @fs.read_file(resolved).binary() catch {
    e => raise @vfs.vfs_error("read_file failed: \{e}")
  }
}

///|
pub async fn RealFs::readdir(
  self : RealFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  let resolved = self.resolve(path)
  @fs.readdir(resolved, sort=true) catch {
    e => raise @vfs.vfs_error("readdir failed: \{e}")
  }
}

///|
pub async fn RealFs::is_dir(self : RealFs, path : String) -> Bool {
  let resolved = self.resolve(path)
  let exists = try? @fs.exists(resolved)
  guard exists is Ok(true) else { return false }
  let k = try? @fs.kind(resolved)
  match k {
    Ok(Directory) => true
    _ => false
  }
}

///|
pub async fn RealFs::is_file(self : RealFs, path : String) -> Bool {
  let resolved = self.resolve(path)
  let exists = try? @fs.exists(resolved)
  guard exists is Ok(true) else { return false }
  let k = try? @fs.kind(resolved)
  match k {
    Ok(Regular) => true
    _ => false
  }
}

///|
pub async fn RealFs::export_snapshot(self : RealFs) -> @vfs.Snapshot {
  let dirs : Array[String] = ["/"]
  let files : Array[@vfs.SnapshotFile] = []
  walk_collect(self.root, "/", dirs, files) catch {
    _ => () // Return what we have so far on error
  }
  @vfs.snapshot(dirs, files)
}

///|
async fn walk_collect(
  os_path : String,
  vfs_path : String,
  dirs : Array[String],
  files : Array[@vfs.SnapshotFile],
) -> Unit {
  let entries = @fs.readdir(os_path, sort=true)
  for entry in entries {
    let child_os = os_path + "/" + entry
    let child_vfs = if vfs_path == "/" {
      "/" + entry
    } else {
      vfs_path + "/" + entry
    }
    let k = @fs.kind(child_os)
    if k is Directory {
      dirs.push(child_vfs)
      walk_collect(child_os, child_vfs, dirs, files)
    } else if k is Regular {
      let data = @fs.read_file(child_os).binary()
      files.push(@vfs.snapshot_file(child_vfs, data))
    }
  }
}

///|
pub async fn RealFs::replace_snapshot(
  self : RealFs,
  snapshot : @vfs.Snapshot,
) -> Unit raise @vfs.VfsError {
  // Clear root directory contents
  try {
    let entries = @fs.readdir(self.root)
    for entry in entries {
      let child = self.root + "/" + entry
      let k = @fs.kind(child)
      if k is Directory {
        @fs.rmdir(child, recursive=true)
      } else {
        @fs.remove(child)
      }
    }
  } catch {
    e => raise @vfs.vfs_error("replace_snapshot clear failed: \{e}")
  }
  // Recreate directories
  for dir in snapshot.dirs {
    if dir == "/" {
      continue
    }
    let resolved = self.resolve(dir)
    @fs.mkdir(resolved, permission=0o755, recursive=true) catch {
      e => raise @vfs.vfs_error("replace_snapshot mkdir failed: \{e}")
    }
  }
  // Recreate files
  for file in snapshot.files {
    let resolved = self.resolve(file.path)
    @fs.write_file(resolved, file.data, create=0o644) catch {
      e => raise @vfs.vfs_error("replace_snapshot write failed: \{e}")
    }
  }
}

// --- Trait implementations ---

///|
impl @vfs.FileSystem for RealFs with mkdir_p(self, path) {
  self.mkdir_p(path)
}

///|
impl @vfs.FileSystem for RealFs with write_file(self, path, content) {
  self.write_file(path, content)
}

///|
impl @vfs.FileSystem for RealFs with write_string(self, path, content) {
  self.write_string(path, content)
}

///|
impl @vfs.FileSystem for RealFs with remove_file(self, path) {
  self.remove_file(path)
}

///|
impl @vfs.FileSystem for RealFs with remove_dir(self, path) {
  self.remove_dir(path)
}

///|
impl @vfs.ReadableFileSystem for RealFs with read_file(self, path) {
  self.read_file(path)
}

///|
impl @vfs.ReadableFileSystem for RealFs with readdir(self, path) {
  self.readdir(path)
}

///|
impl @vfs.ReadableFileSystem for RealFs with is_dir(self, path) {
  self.is_dir(path)
}

///|
impl @vfs.ReadableFileSystem for RealFs with is_file(self, path) {
  self.is_file(path)
}

///|
impl @vfs.Snapshottable for RealFs with export_snapshot(self) {
  self.export_snapshot()
}

///|
impl @vfs.Snapshottable for RealFs with replace_snapshot(self, snapshot) {
  self.replace_snapshot(snapshot)
}
