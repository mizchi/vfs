///|
/// VFS error type.
pub suberror VfsError {
  VfsError(String)
}

///|
pub fn VfsError::to_string(self : VfsError) -> String {
  let VfsError(msg) = self
  msg
}

///|
/// Helper to create VfsError from other packages.
pub fn vfs_error(msg : String) -> VfsError {
  VfsError(msg)
}

///|
/// Core filesystem trait for write operations.
pub(open) trait FileSystem {
  async fn mkdir_p(Self, String) -> Unit raise VfsError
  async fn write_file(Self, String, Bytes) -> Unit raise VfsError
  async fn write_string(Self, String, String) -> Unit raise VfsError
  async fn remove_file(Self, String) -> Unit raise VfsError
  async fn remove_dir(Self, String) -> Unit raise VfsError
}

///|
/// Core filesystem trait for read operations.
pub(open) trait ReadableFileSystem {
  async fn read_file(Self, String) -> Bytes raise VfsError
  async fn readdir(Self, String) -> Array[String] raise VfsError
  async fn is_dir(Self, String) -> Bool
  async fn is_file(Self, String) -> Bool
}

///|
/// Snapshot file entry for bulk export/import.
pub struct SnapshotFile {
  path : String
  data : Bytes
} derive(Eq, Debug)

///|
pub impl Show for SnapshotFile with fn output(self, logger) {
  logger.write_string("{path: ")
  Show::output(self.path, logger)
  logger.write_string(", data: ")
  Show::output(self.data, logger)
  logger.write_string("}")
}

///|
/// Full snapshot of a filesystem state.
pub struct Snapshot {
  dirs : Array[String]
  files : Array[SnapshotFile]
} derive(Eq, Debug)

///|
pub impl Show for Snapshot with fn output(self, logger) {
  logger.write_string("{dirs: ")
  logger.write_string("[")
  for i, dir in self.dirs {
    if i > 0 {
      logger.write_string(", ")
    }
    Show::output(dir, logger)
  }
  logger.write_string("]")
  logger.write_string(", files: ")
  logger.write_string("[")
  for i, file in self.files {
    if i > 0 {
      logger.write_string(", ")
    }
    Show::output(file, logger)
  }
  logger.write_string("]")
  logger.write_string("}")
}

///|
/// Helper to create SnapshotFile.
pub fn snapshot_file(path : String, data : Bytes) -> SnapshotFile {
  { path, data }
}

///|
/// Helper to create Snapshot.
pub fn snapshot(dirs : Array[String], files : Array[SnapshotFile]) -> Snapshot {
  { dirs, files }
}

///|
/// Trait for backends that support snapshot export/import.
pub(open) trait Snapshottable {
  async fn export_snapshot(Self) -> Snapshot
  async fn replace_snapshot(Self, Snapshot) -> Unit raise VfsError
}

///|
/// Trait for backends with buffered writes.
pub(open) trait Flushable {
  async fn flush(Self) -> Unit raise VfsError
  async fn sync(Self) -> Unit raise VfsError
  fn dirty(Self) -> Bool
}

///|
/// Event types for inter-tab notification.
pub(all) enum VfsEvent {
  Write(String)
  Remove(String)
  Mkdir(String)
} derive(Eq, Debug)

///|
pub impl Show for VfsEvent with fn output(self, logger) {
  match self {
    Write(s) => {
      logger.write_string("Write(")
      Show::output(s, logger)
      logger.write_string(")")
    }
    Remove(s) => {
      logger.write_string("Remove(")
      Show::output(s, logger)
      logger.write_string(")")
    }
    Mkdir(s) => {
      logger.write_string("Mkdir(")
      Show::output(s, logger)
      logger.write_string(")")
    }
  }
}
