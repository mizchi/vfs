///|
/// Normalize a path: ensure leading /, collapse multiple /, strip trailing /.
pub fn normalize(path : String) -> String {
  if path.is_empty() {
    return "/"
  }
  let buf = StringBuilder::new()
  let mut prev_slash = false
  if path[0] != '/' {
    buf.write_char('/')
  }
  for ch in path {
    if ch == '/' {
      if not(prev_slash) {
        buf.write_char('/')
      }
      prev_slash = true
    } else {
      buf.write_char(ch)
      prev_slash = false
    }
  }
  let result = buf.to_string()
  if result.length() > 1 && result[result.length() - 1] == '/' {
    result[:result.length() - 1].to_string()
  } else {
    result
  }
}

///|
/// Find the last index of a character in a string.
fn last_index_of(s : String, ch : Char) -> Int {
  let mut idx = -1
  for i, c in s {
    if c == ch {
      idx = i
    }
  }
  idx
}

///|
/// Get the parent directory of a path.
pub fn parent(path : String) -> String {
  let normalized = normalize(path)
  if normalized == "/" {
    return "/"
  }
  let idx = last_index_of(normalized, '/')
  if idx <= 0 {
    "/"
  } else {
    normalized[:idx].to_string()
  }
}

///|
/// Get the base name (last component) of a path.
pub fn basename(path : String) -> String {
  let normalized = normalize(path)
  if normalized == "/" {
    return "/"
  }
  let idx = last_index_of(normalized, '/')
  if idx < 0 {
    normalized
  } else {
    normalized[idx + 1:].to_string()
  }
}

///|
/// Join path segments.
pub fn join(parts : Array[String]) -> String {
  normalize(parts.join("/"))
}

///|
/// Find the first occurrence of needle in s starting from position start.
/// Returns -1 if not found.
pub fn index_of(s : String, needle : String, start : Int) -> Int {
  let s_len = s.length()
  let n_len = needle.length()
  if n_len == 0 {
    return start
  }
  if start + n_len > s_len {
    return -1
  }
  for i in start..<=(s_len - n_len) {
    let mut matched = true
    for j in 0..<n_len {
      if s[i + j] != needle[j] {
        matched = false
        break
      }
    }
    if matched {
      return i
    }
  }
  -1
}
