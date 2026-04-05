///|
fn sha256_hex_ffi(_data : Bytes) -> @js_async.Promise[String] {
  abort("sha256_hex_ffi: not implemented for WASM target")
}

///|
fn hmac_sha256_ffi(_key : Bytes, _data : Bytes) -> @js_async.Promise[Bytes] {
  abort("hmac_sha256_ffi: not implemented for WASM target")
}

///|
fn amz_date_now_ffi() -> String {
  abort("amz_date_now_ffi: not implemented for WASM target")
}
