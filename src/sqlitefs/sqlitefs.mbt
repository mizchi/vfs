///|
/// SQLite-backed VFS backend using Node.js node:sqlite.
/// Stores directories and files in two tables.
pub struct SqliteFs {
  db : @sqlite.DatabaseSync
}

///|
pub fn SqliteFs::new(path : String) -> SqliteFs {
  let db = @sqlite.DatabaseSync::new(path)
  db.exec("CREATE TABLE IF NOT EXISTS dirs (path TEXT PRIMARY KEY)")
  db.exec("CREATE TABLE IF NOT EXISTS files (path TEXT PRIMARY KEY, data BLOB)")
  db.exec("INSERT OR IGNORE INTO dirs VALUES ('/')")
  { db, }
}

///|
pub fn SqliteFs::in_memory() -> SqliteFs {
  SqliteFs::new(":memory:")
}

///|
/// Encode a String to UTF-8 Bytes using cached TextEncoder.
extern "js" fn js_string_to_utf8(s : String) -> Bytes =
  #| (s) => (globalThis.__vfsEncoder ??= new TextEncoder()).encode(s)

///|
/// Decode UTF-8 Bytes to String using cached TextDecoder.
extern "js" fn js_utf8_to_string(b : Bytes) -> String =
  #| (b) => (globalThis.__vfsDecoder ??= new TextDecoder()).decode(b instanceof Uint8Array ? b : new Uint8Array(b))

///|
/// Ensure all ancestor directories exist for a normalized path.
fn SqliteFs::ensure_dir_chain(self : SqliteFs, path : String) -> Unit {
  let normalized = @path.normalize(path)
  if normalized == "/" {
    return
  }
  // Check if already exists
  let check = self.db.prepare("SELECT 1 FROM dirs WHERE path = ?")
  if check.get(anonymous_parameters=[@core.any(normalized)]) is Some(_) {
    return
  }
  // Ensure parent chain first
  let par = @path.parent(normalized)
  if par != normalized {
    self.ensure_dir_chain(par)
  }
  // Insert this directory
  let stmt = self.db.prepare("INSERT OR IGNORE INTO dirs VALUES (?)")
  stmt.run(anonymous_parameters=[@core.any(normalized)]) |> ignore
}

///|
pub fn SqliteFs::mkdir_p(
  self : SqliteFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  self.ensure_dir_chain(path)
}

///|
pub fn SqliteFs::write_file(
  self : SqliteFs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  let parent = @path.parent(normalized)
  self.ensure_dir_chain(parent)
  let stmt = self.db.prepare(
    "INSERT OR REPLACE INTO files (path, data) VALUES (?, ?)",
  )
  stmt.run(anonymous_parameters=[@core.any(normalized), @core.any(content)])
  |> ignore
}

///|
pub fn SqliteFs::write_string(
  self : SqliteFs,
  path : String,
  content : String,
) -> Unit raise @vfs.VfsError {
  self.write_file(path, js_string_to_utf8(content))
}

///|
pub fn SqliteFs::read_file(
  self : SqliteFs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  let stmt = self.db.prepare("SELECT data FROM files WHERE path = ?")
  match stmt.get(anonymous_parameters=[@core.any(normalized)]) {
    Some(row) => row["data"].cast()
    None => raise @vfs.vfs_error("File not found: " + normalized)
  }
}

///|
pub fn SqliteFs::read_string(
  self : SqliteFs,
  path : String,
) -> String raise @vfs.VfsError {
  let bytes = self.read_file(path)
  js_utf8_to_string(bytes)
}

///|
pub fn SqliteFs::remove_file(
  self : SqliteFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  let stmt = self.db.prepare("DELETE FROM files WHERE path = ?")
  let result = stmt.run(anonymous_parameters=[@core.any(normalized)])
  if result.changes == 0 {
    raise @vfs.vfs_error("File not found: " + normalized)
  }
}

///|
pub fn SqliteFs::remove_dir(
  self : SqliteFs,
  path : String,
) -> Unit raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  // Check dir exists
  let check = self.db.prepare("SELECT 1 FROM dirs WHERE path = ?")
  if check.get(anonymous_parameters=[@core.any(normalized)]) is None {
    raise @vfs.vfs_error("Directory not found: " + normalized)
  }
  // Delete all files under this dir (prefix match)
  let prefix = if normalized == "/" { "/" } else { normalized + "/" }
  let del_files = self.db.prepare(
    "DELETE FROM files WHERE path LIKE ? OR path = ?",
  )
  del_files.run(anonymous_parameters=[
    @core.any(prefix + "%"),
    @core.any(normalized),
  ])
  |> ignore
  // Delete all subdirs (prefix match) and the dir itself
  let del_dirs = self.db.prepare(
    "DELETE FROM dirs WHERE path LIKE ? OR path = ?",
  )
  del_dirs.run(anonymous_parameters=[
    @core.any(prefix + "%"),
    @core.any(normalized),
  ])
  |> ignore
}

///|
/// List direct children of a directory (returns basenames only).
pub fn SqliteFs::readdir(
  self : SqliteFs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  let normalized = @path.normalize(path)
  // Check dir exists
  let check = self.db.prepare("SELECT 1 FROM dirs WHERE path = ?")
  if check.get(anonymous_parameters=[@core.any(normalized)]) is None {
    raise @vfs.vfs_error("Directory not found: " + normalized)
  }
  let prefix = if normalized == "/" { "/" } else { normalized + "/" }
  let result : Array[String] = []
  let seen : Map[String, Bool] = {}
  // Find direct child dirs
  let dir_stmt = self.db.prepare("SELECT path FROM dirs WHERE path LIKE ?")
  let dirs = dir_stmt.all(anonymous_parameters=[@core.any(prefix + "%")])
  for row in dirs {
    let child_path : String = row["path"].cast()
    // Extract the part after prefix, take first segment
    let relative = child_path[prefix.length():]
    let name = first_segment(relative.to_string())
    if not(name.is_empty()) && not(seen.contains(name)) {
      seen[name] = true
      result.push(name)
    }
  }
  // Find direct child files
  let file_stmt = self.db.prepare("SELECT path FROM files WHERE path LIKE ?")
  let files = file_stmt.all(anonymous_parameters=[@core.any(prefix + "%")])
  for row in files {
    let child_path : String = row["path"].cast()
    let relative = child_path[prefix.length():]
    let name = first_segment(relative.to_string())
    if not(name.is_empty()) && not(seen.contains(name)) {
      seen[name] = true
      result.push(name)
    }
  }
  result
}

///|
/// Extract the first path segment (before the first '/').
fn first_segment(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    if ch == '/' {
      break
    }
    buf.write_char(ch)
  }
  buf.to_string()
}

///|
pub fn SqliteFs::is_dir(self : SqliteFs, path : String) -> Bool {
  let normalized = @path.normalize(path)
  let stmt = self.db.prepare("SELECT 1 FROM dirs WHERE path = ? LIMIT 1")
  stmt.get(anonymous_parameters=[@core.any(normalized)]) is Some(_)
}

///|
pub fn SqliteFs::is_file(self : SqliteFs, path : String) -> Bool {
  let normalized = @path.normalize(path)
  let stmt = self.db.prepare("SELECT 1 FROM files WHERE path = ? LIMIT 1")
  stmt.get(anonymous_parameters=[@core.any(normalized)]) is Some(_)
}

///|
pub fn SqliteFs::export_snapshot(self : SqliteFs) -> @vfs.Snapshot {
  let dir_rows = self.db.prepare("SELECT path FROM dirs").all()
  let dirs : Array[String] = []
  for row in dir_rows {
    dirs.push(row["path"].cast())
  }
  let file_rows = self.db.prepare("SELECT path, data FROM files").all()
  let files : Array[@vfs.SnapshotFile] = []
  for row in file_rows {
    let path : String = row["path"].cast()
    let data : Bytes = row["data"].cast()
    files.push(@vfs.snapshot_file(path, data))
  }
  @vfs.snapshot(dirs, files)
}

///|
pub fn SqliteFs::replace_snapshot(
  self : SqliteFs,
  snapshot : @vfs.Snapshot,
) -> Unit raise @vfs.VfsError {
  self.db.exec("DELETE FROM files")
  self.db.exec("DELETE FROM dirs")
  self.db.exec("INSERT OR IGNORE INTO dirs VALUES ('/')")
  for dir in snapshot.dirs {
    self.ensure_dir_chain(dir)
  }
  for file in snapshot.files {
    let normalized = @path.normalize(file.path)
    let parent = @path.parent(normalized)
    self.ensure_dir_chain(parent)
    let stmt = self.db.prepare(
      "INSERT OR REPLACE INTO files (path, data) VALUES (?, ?)",
    )
    stmt.run(anonymous_parameters=[@core.any(normalized), @core.any(file.data)])
    |> ignore
  }
}

// --- Trait implementations ---

///|
impl @vfs.FileSystem for SqliteFs with mkdir_p(self, path) {
  self.mkdir_p(path)
}

///|
impl @vfs.FileSystem for SqliteFs with write_file(self, path, content) {
  self.write_file(path, content)
}

///|
impl @vfs.FileSystem for SqliteFs with write_string(self, path, content) {
  self.write_string(path, content)
}

///|
impl @vfs.FileSystem for SqliteFs with remove_file(self, path) {
  self.remove_file(path)
}

///|
impl @vfs.FileSystem for SqliteFs with remove_dir(self, path) {
  self.remove_dir(path)
}

///|
impl @vfs.ReadableFileSystem for SqliteFs with read_file(self, path) {
  self.read_file(path)
}

///|
impl @vfs.ReadableFileSystem for SqliteFs with readdir(self, path) {
  self.readdir(path)
}

///|
impl @vfs.ReadableFileSystem for SqliteFs with is_dir(self, path) {
  self.is_dir(path)
}

///|
impl @vfs.ReadableFileSystem for SqliteFs with is_file(self, path) {
  self.is_file(path)
}

///|
impl @vfs.Snapshottable for SqliteFs with export_snapshot(self) {
  self.export_snapshot()
}

///|
impl @vfs.Snapshottable for SqliteFs with replace_snapshot(self, snapshot) {
  self.replace_snapshot(snapshot)
}
