///|
/// WASM target fallback for string encoding.
/// Uses MoonBit's built-in String/Bytes conversion.
fn js_string_to_utf8(s : String) -> Bytes {
  s.to_bytes()
}

///|
fn js_utf8_to_string(b : Bytes) -> String {
  b.to_unchecked_string()
}

///|
fn js_clone_bytes(b : Bytes) -> Bytes {
  b
}
