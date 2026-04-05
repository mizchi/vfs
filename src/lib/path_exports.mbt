// JS API exports for path utilities.

///|
pub fn path_normalize(path : String) -> String {
  @path.normalize(path)
}

///|
pub fn path_parent(path : String) -> String {
  @path.parent(path)
}

///|
pub fn path_basename(path : String) -> String {
  @path.basename(path)
}

///|
pub fn path_join(parts : Array[String]) -> String {
  @path.join(parts)
}
