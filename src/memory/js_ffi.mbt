///|
/// JS FFI for UTF-8 string encoding/decoding.

///|
/// Encode a String to UTF-8 Bytes using cached TextEncoder.
pub extern "js" fn js_string_to_utf8(s : String) -> Bytes =
  #| (s) => (globalThis.__vfsEncoder ??= new TextEncoder()).encode(s)

///|
/// Decode UTF-8 Bytes to String using cached TextDecoder.
pub extern "js" fn js_utf8_to_string(b : Bytes) -> String =
  #| (b) => (globalThis.__vfsDecoder ??= new TextDecoder()).decode(b instanceof Uint8Array ? b : new Uint8Array(b))

///|
/// Fast Uint8Array clone via slice() — avoids MoonBit Bytes copy overhead.
pub extern "js" fn js_clone_bytes(b : Bytes) -> Bytes =
  #| (b) => (b instanceof Uint8Array ? b.slice() : new Uint8Array(b))
