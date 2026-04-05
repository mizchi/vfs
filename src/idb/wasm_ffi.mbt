///|
fn idb_load_ffi(_db_name : String) -> @js_async.Promise[@vfs.Snapshot?] {
  abort("idb_load_ffi: not implemented for WASM target")
}

///|
fn idb_save_ffi(
  _db_name : String,
  _snapshot : @vfs.Snapshot,
) -> @js_async.Promise[Unit] {
  abort("idb_save_ffi: not implemented for WASM target")
}
