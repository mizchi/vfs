/// VFS error type.
pub suberror VfsError {
  VfsError(String)
}

pub fn VfsError::to_string(self : VfsError) -> String {
  let VfsError(msg) = self
  msg
}

/// Helper to create VfsError from other packages.
pub fn vfs_error(msg : String) -> VfsError {
  VfsError(msg)
}

/// Core filesystem trait for write operations.
pub(open) trait FileSystem {
  mkdir_p(Self, String) -> Unit raise VfsError
  write_file(Self, String, Bytes) -> Unit raise VfsError
  write_string(Self, String, String) -> Unit raise VfsError
  remove_file(Self, String) -> Unit raise VfsError
  remove_dir(Self, String) -> Unit raise VfsError
}

/// Core filesystem trait for read operations.
pub(open) trait ReadableFileSystem {
  read_file(Self, String) -> Bytes raise VfsError
  readdir(Self, String) -> Array[String] raise VfsError
  is_dir(Self, String) -> Bool
  is_file(Self, String) -> Bool
}

/// Snapshot file entry for bulk export/import.
pub struct SnapshotFile {
  path : String
  data : Bytes
} derive(Eq, Show)

/// Full snapshot of a filesystem state.
pub struct Snapshot {
  dirs : Array[String]
  files : Array[SnapshotFile]
} derive(Eq, Show)

/// Helper to create SnapshotFile.
pub fn snapshot_file(path : String, data : Bytes) -> SnapshotFile {
  { path, data }
}

/// Helper to create Snapshot.
pub fn snapshot(dirs : Array[String], files : Array[SnapshotFile]) -> Snapshot {
  { dirs, files }
}

/// Trait for backends that support snapshot export/import.
pub(open) trait Snapshottable {
  export_snapshot(Self) -> Snapshot
  replace_snapshot(Self, Snapshot) -> Unit raise VfsError
}

/// Trait for backends with buffered writes.
pub(open) trait Flushable {
  flush(Self) -> Unit raise VfsError
  sync(Self) -> Unit raise VfsError
  dirty(Self) -> Bool
}

/// Event types for inter-tab notification.
pub enum VfsEvent {
  Write(String)
  Remove(String)
  Mkdir(String)
  Flush
} derive(Eq, Show)
