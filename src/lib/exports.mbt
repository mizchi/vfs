// JS API exports for mizchi/vfs.
// Thin wrappers to flatten the API for JS consumption.

// --- MemoryFs factory ---

pub fn create_memory_fs() -> @memory.MemoryFs {
  @memory.MemoryFs::new()
}

// --- FileSystem write ops ---

pub async fn mkdir_p(fs : @memory.MemoryFs, path : String) -> Unit raise @vfs.VfsError {
  fs.mkdir_p(path)
}

pub async fn write_file(fs : @memory.MemoryFs, path : String, content : Bytes) -> Unit raise @vfs.VfsError {
  fs.write_file(path, content)
}

pub async fn write_string(fs : @memory.MemoryFs, path : String, content : String) -> Unit raise @vfs.VfsError {
  fs.write_string(path, content)
}

pub async fn remove_file(fs : @memory.MemoryFs, path : String) -> Unit raise @vfs.VfsError {
  fs.remove_file(path)
}

pub async fn remove_dir(fs : @memory.MemoryFs, path : String) -> Unit raise @vfs.VfsError {
  fs.remove_dir(path)
}

// --- ReadableFileSystem read ops ---

pub async fn read_file(fs : @memory.MemoryFs, path : String) -> Bytes raise @vfs.VfsError {
  fs.read_file(path)
}

pub async fn read_string(fs : @memory.MemoryFs, path : String) -> String raise @vfs.VfsError {
  fs.read_string(path)
}

pub async fn readdir(fs : @memory.MemoryFs, path : String) -> Array[String] raise @vfs.VfsError {
  fs.readdir(path)
}

pub fn is_dir(fs : @memory.MemoryFs, path : String) -> Bool {
  fs.is_dir(path)
}

pub fn is_file(fs : @memory.MemoryFs, path : String) -> Bool {
  fs.is_file(path)
}

// --- Snapshot ops ---

pub fn export_snapshot(fs : @memory.MemoryFs) -> @vfs.Snapshot {
  fs.export_snapshot()
}

pub async fn replace_snapshot(fs : @memory.MemoryFs, snapshot : @vfs.Snapshot) -> Unit raise @vfs.VfsError {
  fs.replace_snapshot(snapshot)
}

pub fn reset(fs : @memory.MemoryFs) -> Unit {
  fs.reset()
}

// --- Path utils ---

pub fn path_normalize(path : String) -> String {
  @path.normalize(path)
}

pub fn path_parent(path : String) -> String {
  @path.parent(path)
}

pub fn path_basename(path : String) -> String {
  @path.basename(path)
}

pub fn path_join(parts : Array[String]) -> String {
  @path.join(parts)
}
