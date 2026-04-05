///|
/// WASM target fallback for string encoding.
/// Uses MoonBit's built-in String/Bytes conversion.
pub fn js_string_to_utf8(s : String) -> Bytes {
  s.to_bytes()
}

///|
pub fn js_utf8_to_string(b : Bytes) -> String {
  b.to_unchecked_string()
}

///|
pub fn js_clone_bytes(b : Bytes) -> Bytes {
  b
}
