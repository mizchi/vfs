// JS API exports for mizchi/vfs.
// Thin wrappers to flatten the API for JS consumption.

// --- MemoryFs factory ---

///|
pub fn create_memory_fs() -> @memory.MemoryFs {
  @memory.MemoryFs::new()
}

// --- FileSystem write ops ---

///|
pub async fn mkdir_p(
  fs : @memory.MemoryFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.mkdir_p(path)
}

///|
pub async fn write_file(
  fs : @memory.MemoryFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  fs.write_file(path, content)
}

///|
pub async fn write_string(
  fs : @memory.MemoryFs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  fs.write_string(path, content)
}

///|
pub async fn remove_file(
  fs : @memory.MemoryFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_file(path)
}

///|
pub async fn remove_dir(
  fs : @memory.MemoryFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_dir(path)
}

// --- ReadableFileSystem read ops ---

///|
pub async fn read_file(
  fs : @memory.MemoryFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  fs.read_file(path)
}

///|
pub async fn read_string(
  fs : @memory.MemoryFs,
  path : String,
) -> String raise @vfs.VfsError {
  fs.read_string(path)
}

///|
pub async fn readdir(
  fs : @memory.MemoryFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  fs.readdir(path)
}

///|
pub fn is_dir(fs : @memory.MemoryFs, path : String) -> Bool {
  fs.is_dir(path)
}

///|
pub fn is_file(fs : @memory.MemoryFs, path : String) -> Bool {
  fs.is_file(path)
}

// --- Snapshot ops ---

///|
pub fn export_snapshot(fs : @memory.MemoryFs) -> @vfs.Snapshot {
  fs.export_snapshot()
}

///|
pub async fn replace_snapshot(
  fs : @memory.MemoryFs,
  snapshot : @vfs.Snapshot,
) -> Unit raise @vfs.VfsError {
  fs.replace_snapshot(snapshot)
}

///|
pub fn reset(fs : @memory.MemoryFs) -> Unit {
  fs.reset()
}

// --- Path utils ---

///|
pub fn path_normalize(path : String) -> String {
  @path.normalize(path)
}

///|
pub fn path_parent(path : String) -> String {
  @path.parent(path)
}

///|
pub fn path_basename(path : String) -> String {
  @path.basename(path)
}

///|
pub fn path_join(parts : Array[String]) -> String {
  @path.join(parts)
}

// --- S3 factory ---

///|
pub fn create_s3_client(
  endpoint : String,
  bucket : String,
  region : String,
  access_key_id : String,
  secret_access_key : String,
) -> @s3client.S3Client {
  @s3client.S3Client::new(
    @s3client.S3Config::new(
      endpoint~,
      bucket~,
      region~,
      access_key_id~,
      secret_access_key~,
    ),
  )
}

///|
pub fn create_s3fs(client : @s3client.S3Client, prefix : String) -> @s3fs.S3Fs {
  @s3fs.S3Fs::new(client, prefix~)
}

// --- S3Fs operations ---

///|
pub async fn s3_mkdir_p(
  fs : @s3fs.S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.mkdir_p(path)
}

///|
pub async fn s3_write_file(
  fs : @s3fs.S3Fs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  fs.write_file(path, content)
}

///|
pub async fn s3_read_file(
  fs : @s3fs.S3Fs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  fs.read_file(path)
}

///|
pub async fn s3_remove_file(
  fs : @s3fs.S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_file(path)
}

///|
pub async fn s3_remove_dir(
  fs : @s3fs.S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_dir(path)
}

///|
pub async fn s3_readdir(
  fs : @s3fs.S3Fs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  fs.readdir(path)
}

///|
pub async fn s3_is_dir(fs : @s3fs.S3Fs, path : String) -> Bool {
  fs.is_dir(path)
}

///|
pub async fn s3_is_file(fs : @s3fs.S3Fs, path : String) -> Bool {
  fs.is_file(path)
}

// --- IndexedDbFs factory ---

///|
pub fn create_idb_fs() -> @idb.IndexedDbFs {
  @idb.IndexedDbFs::new()
}

// --- IndexedDbFs operations ---

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

// --- SqliteFs factory ---

///|
pub fn create_sqlite_fs(path : String) -> @sqlitefs.SqliteFs {
  @sqlitefs.SqliteFs::new(path)
}

///|
pub fn create_sqlite_fs_memory() -> @sqlitefs.SqliteFs {
  @sqlitefs.SqliteFs::in_memory()
}

// --- SqliteFs operations ---

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
