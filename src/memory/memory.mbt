///|
/// In-memory VFS backend.
/// Uses a children map for O(1) readdir lookups.
pub struct MemoryFs {
  priv files : Map[String, Bytes]
  priv dirs : Set[String]
  priv children : Map[String, Set[String]]
}

///|
pub fn MemoryFs::new() -> MemoryFs {
  let dirs : Set[String] = Set::new()
  dirs.add("/")
  let children : Map[String, Set[String]] = Map::new()
  children["/"] = Set::new()
  { files: Map::new(), dirs, children }
}

///|
/// Register a child entry under its parent directory.
fn MemoryFs::add_child(self : MemoryFs, parent : String, name : String) -> Unit {
  match self.children.get(parent) {
    Some(set) => set.add(name)
    None => {
      let set : Set[String] = Set::new()
      set.add(name)
      self.children[parent] = set
    }
  }
}

///|
/// Remove a child entry from its parent directory.
fn MemoryFs::remove_child(
  self : MemoryFs,
  parent : String,
  name : String,
) -> Unit {
  match self.children.get(parent) {
    Some(set) => set.remove(name)
    None => ()
  }
}

///|
/// Ensure all ancestor directories exist for a path.
fn MemoryFs::ensure_dir_chain(self : MemoryFs, path : String) -> Unit {
  let normalized = @path.normalize(path)
  if normalized == "/" || self.dirs.contains(normalized) {
    // Already exists, nothing to do
    return
  }
  // Ensure parent chain first (recursive but shallow — stops at existing dir)
  let par = @path.parent(normalized)
  if par != normalized {
    self.ensure_dir_chain(par)
  }
  // Create this directory
  self.dirs.add(normalized)
  self.children[normalized] = Set::new()
  self.add_child(par, @path.basename(normalized))
}

///|
pub fn MemoryFs::mkdir_p(
  self : MemoryFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  self.ensure_dir_chain(path)
}

///|
pub fn MemoryFs::write_file(
  self : MemoryFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  let parent = @path.parent(normalized)
  self.ensure_dir_chain(parent)
  self.files[normalized] = content
  // Register file as child of its parent
  self.add_child(parent, @path.basename(normalized))
}

///|
pub fn MemoryFs::write_string(
  self : MemoryFs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  self.write_file(path, js_string_to_utf8(content))
}

///|
pub fn MemoryFs::remove_file(
  self : MemoryFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  if not(self.files.contains(normalized)) {
    raise @vfs.vfs_error("File not found: " + normalized)
  }
  self.files.remove(normalized)
  self.remove_child(@path.parent(normalized), @path.basename(normalized))
}

///|
pub fn MemoryFs::remove_dir(
  self : MemoryFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  if not(self.dirs.contains(normalized)) {
    raise @vfs.vfs_error("Directory not found: " + normalized)
  }
  // Recursively remove all children first
  let child_set = self.children.get(normalized)
  match child_set {
    Some(set) => {
      let names = set.to_array()
      for name in names {
        let child_path = if normalized == "/" {
          "/" + name
        } else {
          normalized + "/" + name
        }
        if self.dirs.contains(child_path) {
          self.remove_dir(child_path) |> ignore
        } else if self.files.contains(child_path) {
          self.files.remove(child_path)
        }
      }
    }
    None => ()
  }
  self.dirs.remove(normalized)
  self.children.remove(normalized)
  self.remove_child(@path.parent(normalized), @path.basename(normalized))
}

///|
pub fn MemoryFs::read_file(
  self : MemoryFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  match self.files.get(normalized) {
    Some(data) => data
    None => raise @vfs.vfs_error("File not found: " + normalized)
  }
}

///|
pub fn MemoryFs::read_string(
  self : MemoryFs,
  path : String,
) -> String raise @vfs.VfsError {
  let bytes = self.read_file(path)
  js_utf8_to_string(bytes)
}

///|
/// O(1) readdir using children map.
pub fn MemoryFs::readdir(
  self : MemoryFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  if not(self.dirs.contains(normalized)) {
    raise @vfs.vfs_error("Directory not found: " + normalized)
  }
  match self.children.get(normalized) {
    Some(set) => set.to_array()
    None => []
  }
}

///|
pub fn MemoryFs::is_dir(self : MemoryFs, path : String) -> Bool {
  self.dirs.contains(@path.normalize(path))
}

///|
pub fn MemoryFs::is_file(self : MemoryFs, path : String) -> Bool {
  self.files.contains(@path.normalize(path))
}

///|
pub fn MemoryFs::reset(self : MemoryFs) -> Unit {
  self.files.clear()
  self.dirs.clear()
  self.children.clear()
  self.dirs.add("/")
  self.children["/"] = Set::new()
}

///|
/// Export snapshot. Files are returned in iteration order (no sort needed for correctness).
pub fn MemoryFs::export_snapshot(self : MemoryFs) -> @vfs.Snapshot {
  let dirs = self.dirs.to_array()
  let file_entries : Array[@vfs.SnapshotFile] = Array::new(
    capacity=self.files.length(),
  )
  for path, data in self.files {
    file_entries.push(@vfs.snapshot_file(path, data))
  }
  @vfs.snapshot(dirs, file_entries)
}

// --- Trait implementations ---

///|
impl @vfs.FileSystem for MemoryFs with mkdir_p(self, path) {
  self.mkdir_p(path)
}

///|
impl @vfs.FileSystem for MemoryFs with write_file(self, path, content) {
  self.write_file(path, content)
}

///|
impl @vfs.FileSystem for MemoryFs with write_string(self, path, content) {
  self.write_string(path, content)
}

///|
impl @vfs.FileSystem for MemoryFs with remove_file(self, path) {
  self.remove_file(path)
}

///|
impl @vfs.FileSystem for MemoryFs with remove_dir(self, path) {
  self.remove_dir(path)
}

///|
impl @vfs.ReadableFileSystem for MemoryFs with read_file(self, path) {
  self.read_file(path)
}

///|
impl @vfs.ReadableFileSystem for MemoryFs with readdir(self, path) {
  self.readdir(path)
}

///|
impl @vfs.ReadableFileSystem for MemoryFs with is_dir(self, path) {
  self.is_dir(path)
}

///|
impl @vfs.ReadableFileSystem for MemoryFs with is_file(self, path) {
  self.is_file(path)
}

///|
pub fn MemoryFs::replace_snapshot(
  self : MemoryFs,
  snapshot : @vfs.Snapshot,
) -> Unit raise @vfs.VfsError {
  self.reset()
  for dir in snapshot.dirs {
    self.ensure_dir_chain(dir)
  }
  for file in snapshot.files {
    let normalized = @path.normalize(file.path)
    let parent = @path.parent(normalized)
    self.ensure_dir_chain(parent)
    self.files[normalized] = file.data
    self.add_child(parent, @path.basename(normalized))
  }
}
