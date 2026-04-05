// JS API exports for IndexedDbFs.

///|
pub fn create_idb_fs() -> @idb.IndexedDbFs {
  @idb.IndexedDbFs::new()
}

///|
pub async fn idb_mkdir_p(
  fs : @idb.IndexedDbFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.mkdir_p(path)
}

///|
pub async fn idb_write_file(
  fs : @idb.IndexedDbFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  fs.write_file(path, content)
}

///|
pub async fn idb_write_string(
  fs : @idb.IndexedDbFs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  fs.write_string(path, content)
}

///|
pub fn idb_read_file(
  fs : @idb.IndexedDbFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  fs.read_file(path)
}

///|
pub fn idb_read_string(
  fs : @idb.IndexedDbFs,
  path : String,
) -> String raise @vfs.VfsError {
  fs.read_string(path)
}

///|
pub fn idb_readdir(
  fs : @idb.IndexedDbFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  fs.readdir(path)
}

///|
pub fn idb_is_dir(fs : @idb.IndexedDbFs, path : String) -> Bool {
  fs.is_dir(path)
}

///|
pub fn idb_is_file(fs : @idb.IndexedDbFs, path : String) -> Bool {
  fs.is_file(path)
}

///|
pub async fn idb_remove_file(
  fs : @idb.IndexedDbFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_file(path)
}

///|
pub async fn idb_remove_dir(
  fs : @idb.IndexedDbFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_dir(path)
}

///|
pub async fn idb_flush(fs : @idb.IndexedDbFs) -> Unit raise @vfs.VfsError {
  fs.flush()
}

///|
pub fn idb_dirty(fs : @idb.IndexedDbFs) -> Bool {
  fs.dirty()
}
