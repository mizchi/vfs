///|
/// IndexedDB-backed VFS. Wraps MemoryFs for fast in-memory operations,
/// persists via IDB snapshot flush/hydrate.
pub struct IndexedDbFs {
  priv inner : @memory.MemoryFs
  priv db_name : String
  priv mut dirty : Bool
  priv mut write_count : Int
  priv auto_flush_threshold : Int
}

///|
/// Create a new IndexedDbFs. Call `hydrate()` after creation to load from IDB.
pub fn IndexedDbFs::new(
  db_name? : String = "mizchi-vfs",
  auto_flush_threshold? : Int = 0,
) -> IndexedDbFs {
  {
    inner: @memory.MemoryFs::new(),
    db_name,
    dirty: false,
    write_count: 0,
    auto_flush_threshold,
  }
}

///|
/// Factory: create and hydrate from IDB in one step.
pub async fn IndexedDbFs::create(
  db_name? : String = "mizchi-vfs",
  auto_flush_threshold? : Int = 0,
) -> IndexedDbFs raise @vfs.VfsError {
  let fs = IndexedDbFs::new(db_name~, auto_flush_threshold~)
  fs.hydrate()
  fs
}

///|
/// Load snapshot from IDB and restore into memory.
pub async fn IndexedDbFs::hydrate(
  self : IndexedDbFs,
) -> Unit raise @vfs.VfsError {
  let snapshot : @vfs.Snapshot? = idb_load_ffi(self.db_name).wait() catch {
    e => raise @vfs.vfs_error("IDB load failed: \{e}")
  }
  match snapshot {
    Some(s) => self.inner.replace_snapshot(s)
    None => ()
  }
  self.dirty = false
  self.write_count = 0
}

///|
async fn IndexedDbFs::mark_dirty(
  self : IndexedDbFs,
) -> Unit raise @vfs.VfsError {
  self.dirty = true
  self.write_count += 1
  if self.auto_flush_threshold > 0 &&
    self.write_count >= self.auto_flush_threshold {
    self.flush()
    self.write_count = 0
  }
}

// --- FileSystem trait ---

///|
pub async fn IndexedDbFs::mkdir_p(
  self : IndexedDbFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  self.inner.mkdir_p(path)
  self.mark_dirty()
}

///|
pub async fn IndexedDbFs::write_file(
  self : IndexedDbFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  self.inner.write_file(path, content)
  self.mark_dirty()
}

///|
pub async fn IndexedDbFs::write_string(
  self : IndexedDbFs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  self.inner.write_string(path, content)
  self.mark_dirty()
}

///|
pub async fn IndexedDbFs::remove_file(
  self : IndexedDbFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  self.inner.remove_file(path)
  self.mark_dirty()
}

///|
pub async fn IndexedDbFs::remove_dir(
  self : IndexedDbFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  self.inner.remove_dir(path)
  self.mark_dirty()
}

// --- ReadableFileSystem trait ---

///|
pub fn IndexedDbFs::read_file(
  self : IndexedDbFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  self.inner.read_file(path)
}

///|
pub fn IndexedDbFs::read_string(
  self : IndexedDbFs,
  path : String,
) -> String raise @vfs.VfsError {
  self.inner.read_string(path)
}

///|
pub fn IndexedDbFs::readdir(
  self : IndexedDbFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  self.inner.readdir(path)
}

///|
pub fn IndexedDbFs::is_dir(self : IndexedDbFs, path : String) -> Bool {
  self.inner.is_dir(path)
}

///|
pub fn IndexedDbFs::is_file(self : IndexedDbFs, path : String) -> Bool {
  self.inner.is_file(path)
}

// --- Snapshottable trait ---

///|
pub fn IndexedDbFs::export_snapshot(self : IndexedDbFs) -> @vfs.Snapshot {
  self.inner.export_snapshot()
}

///|
pub async fn IndexedDbFs::replace_snapshot(
  self : IndexedDbFs,
  snapshot : @vfs.Snapshot,
) -> Unit raise @vfs.VfsError {
  self.inner.replace_snapshot(snapshot)
  self.dirty = true
}

// --- Flushable trait ---

///|
pub async fn IndexedDbFs::flush(self : IndexedDbFs) -> Unit raise @vfs.VfsError {
  if not(self.dirty) {
    return
  }
  let snapshot = self.inner.export_snapshot()
  idb_save_ffi(self.db_name, snapshot).wait() catch {
    e => raise @vfs.vfs_error("IDB save failed: \{e}")
  }
  self.dirty = false
}

///|
pub async fn IndexedDbFs::sync(self : IndexedDbFs) -> Unit raise @vfs.VfsError {
  self.flush()
}

///|
pub fn IndexedDbFs::dirty(self : IndexedDbFs) -> Bool {
  self.dirty
}

///|
pub fn IndexedDbFs::reset(self : IndexedDbFs) -> Unit {
  self.inner.reset()
  self.dirty = true
}

// --- Trait implementations ---

///|
impl @vfs.FileSystem for IndexedDbFs with mkdir_p(self, path) {
  self.mkdir_p(path)
}

///|
impl @vfs.FileSystem for IndexedDbFs with write_file(self, path, content) {
  self.write_file(path, content)
}

///|
impl @vfs.FileSystem for IndexedDbFs with write_string(self, path, content) {
  self.write_string(path, content)
}

///|
impl @vfs.FileSystem for IndexedDbFs with remove_file(self, path) {
  self.remove_file(path)
}

///|
impl @vfs.FileSystem for IndexedDbFs with remove_dir(self, path) {
  self.remove_dir(path)
}

///|
impl @vfs.ReadableFileSystem for IndexedDbFs with read_file(self, path) {
  self.read_file(path)
}

///|
impl @vfs.ReadableFileSystem for IndexedDbFs with readdir(self, path) {
  self.readdir(path)
}

///|
impl @vfs.ReadableFileSystem for IndexedDbFs with is_dir(self, path) {
  self.is_dir(path)
}

///|
impl @vfs.ReadableFileSystem for IndexedDbFs with is_file(self, path) {
  self.is_file(path)
}

///|
impl @vfs.Snapshottable for IndexedDbFs with export_snapshot(self) {
  self.export_snapshot()
}

///|
impl @vfs.Snapshottable for IndexedDbFs with replace_snapshot(self, snapshot) {
  self.replace_snapshot(snapshot)
}

///|
impl @vfs.Flushable for IndexedDbFs with flush(self) {
  self.flush()
}

///|
impl @vfs.Flushable for IndexedDbFs with sync(self) {
  self.sync()
}

///|
impl @vfs.Flushable for IndexedDbFs with dirty(self) {
  self.dirty()
}
