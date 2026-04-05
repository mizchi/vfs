// JS API exports for SqliteFs.

///|
pub fn create_sqlite_fs(path : String) -> @sqlitefs.SqliteFs {
  @sqlitefs.SqliteFs::new(path)
}

///|
pub fn create_sqlite_fs_memory() -> @sqlitefs.SqliteFs {
  @sqlitefs.SqliteFs::in_memory()
}

///|
pub fn sqlite_mkdir_p(
  fs : @sqlitefs.SqliteFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.mkdir_p(path)
}

///|
pub fn sqlite_write_file(
  fs : @sqlitefs.SqliteFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  fs.write_file(path, content)
}

///|
pub fn sqlite_read_file(
  fs : @sqlitefs.SqliteFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  fs.read_file(path)
}

///|
pub fn sqlite_readdir(
  fs : @sqlitefs.SqliteFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  fs.readdir(path)
}

///|
pub fn sqlite_is_dir(fs : @sqlitefs.SqliteFs, path : String) -> Bool {
  fs.is_dir(path)
}

///|
pub fn sqlite_is_file(fs : @sqlitefs.SqliteFs, path : String) -> Bool {
  fs.is_file(path)
}

///|
pub fn sqlite_remove_file(
  fs : @sqlitefs.SqliteFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_file(path)
}

///|
pub fn sqlite_remove_dir(
  fs : @sqlitefs.SqliteFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_dir(path)
}
