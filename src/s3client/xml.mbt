///|
fn string_index_of(haystack : String, needle : String, from : Int) -> Int {
  let h_len = haystack.length()
  let n_len = needle.length()
  if n_len == 0 { return from }
  if from + n_len > h_len { return -1 }
  for i in from..=(h_len - n_len) {
    let mut matched = true
    for j in 0..<n_len {
      if haystack[i + j] != needle[j] {
        matched = false
        break
      }
    }
    if matched { return i }
  }
  -1
}

///|
pub fn extract_tag_values(xml : String, tag : String) -> Array[String] {
  let results : Array[String] = []
  let open_tag = "<\{tag}>"
  let close_tag = "</\{tag}>"
  let mut pos = 0
  while pos < xml.length() {
    let start = string_index_of(xml, open_tag, pos)
    if start < 0 { break }
    let content_start = start + open_tag.length()
    let end_pos = string_index_of(xml, close_tag, content_start)
    if end_pos < 0 { break }
    results.push(xml.substring(start=content_start, end=end_pos))
    pos = end_pos + close_tag.length()
  }
  results
}

///|
pub fn parse_list_objects_v2(xml : String) -> Array[S3Object] {
  let keys = extract_tag_values(xml, "Key")
  let sizes = extract_tag_values(xml, "Size")
  let results : Array[S3Object] = []
  for i in 0..<keys.length() {
    let size : Int64 = if i < sizes.length() {
      try { @strconv.parse_int64(sizes[i]) } catch { _ => 0L }
    } else { 0L }
    results.push({ key: keys[i], size })
  }
  results
}
