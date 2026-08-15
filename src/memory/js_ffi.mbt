///|
/// JS FFI for UTF-8 string encoding/decoding.

///|
/// Encode a String to UTF-8 Bytes using cached TextEncoder.
extern "js" fn js_string_to_utf8(s : String) -> Bytes =
  #| (s) => (globalThis.__vfsEncoder ??= new TextEncoder()).encode(s)

///|
/// Decode UTF-8 Bytes to String using cached TextDecoder.
extern "js" fn js_utf8_to_string(b : Bytes) -> String =
  #| (b) => (globalThis.__vfsDecoder ??= new TextDecoder()).decode(b instanceof Uint8Array ? b : new Uint8Array(b))
