///|
/// WASM target fallback for string encoding.
/// Uses MoonBit's built-in String/Bytes conversion.
fn js_string_to_utf8(s : String) -> Bytes {
  @utf8.encode(s)
}

///|
fn js_utf8_to_string(b : Bytes) -> String {
  @utf8.decode(b) catch {
    _ => b.to_unchecked_string()
  }
}
