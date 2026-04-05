///|
test "normalize: empty" {
  assert_eq(normalize(""), "/")
}

///|
test "normalize: root" {
  assert_eq(normalize("/"), "/")
}

///|
test "normalize: no leading slash" {
  assert_eq(normalize("foo/bar"), "/foo/bar")
}

///|
test "normalize: trailing slash" {
  assert_eq(normalize("/foo/bar/"), "/foo/bar")
}

///|
test "normalize: double slashes" {
  assert_eq(normalize("/foo//bar///baz"), "/foo/bar/baz")
}

///|
test "parent: root" {
  assert_eq(parent("/"), "/")
}

///|
test "parent: top-level" {
  assert_eq(parent("/foo"), "/")
}

///|
test "parent: nested" {
  assert_eq(parent("/foo/bar/baz"), "/foo/bar")
}

///|
test "basename: root" {
  assert_eq(basename("/"), "/")
}

///|
test "basename: file" {
  assert_eq(basename("/foo/bar.txt"), "bar.txt")
}

///|
test "basename: dir" {
  assert_eq(basename("/foo/bar"), "bar")
}

///|
test "join: basic" {
  assert_eq(join(["/foo", "bar", "baz"]), "/foo/bar/baz")
}

///|
test "join: with slashes" {
  assert_eq(join(["/foo/", "/bar/"]), "/foo/bar")
}
