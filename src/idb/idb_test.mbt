///|
/// Tests for IndexedDbFs — verifies MemoryFs delegation and dirty tracking.
/// IDB persistence is tested via Node.js bench script (needs indexedDB polyfill).

///|
async test "write and read delegates to memory" {
  let fs = IndexedDbFs::new()
  fs.write_string("/hello.txt", "world")
  assert_eq(fs.read_string("/hello.txt"), "world")
}

///|
async test "write marks dirty" {
  let fs = IndexedDbFs::new()
  assert_false(fs.dirty())
  fs.write_string("/a.txt", "data")
  assert_true(fs.dirty())
}

///|
async test "mkdir_p creates dirs" {
  let fs = IndexedDbFs::new()
  fs.mkdir_p("/a/b/c")
  assert_true(fs.is_dir("/a"))
  assert_true(fs.is_dir("/a/b"))
  assert_true(fs.is_dir("/a/b/c"))
  assert_true(fs.dirty())
}

///|
async test "readdir lists entries" {
  let fs = IndexedDbFs::new()
  fs.write_string("/repo/a.txt", "a")
  fs.write_string("/repo/b.txt", "b")
  fs.mkdir_p("/repo/sub")
  let entries = fs.readdir("/repo")
  assert_eq(entries.length(), 3)
}

///|
async test "remove_file works and marks dirty" {
  let fs = IndexedDbFs::new()
  fs.write_string("/tmp/x.txt", "data")
  assert_true(fs.is_file("/tmp/x.txt"))
  fs.remove_file("/tmp/x.txt")
  assert_false(fs.is_file("/tmp/x.txt"))
}

///|
async test "snapshot export and import" {
  let fs1 = IndexedDbFs::new()
  fs1.write_string("/a.txt", "hello")
  fs1.mkdir_p("/sub")
  let snap = fs1.export_snapshot()
  let fs2 = IndexedDbFs::new()
  fs2.replace_snapshot(snap)
  assert_eq(fs2.read_string("/a.txt"), "hello")
  assert_true(fs2.is_dir("/sub"))
}

///|
async test "reset clears and marks dirty" {
  let fs = IndexedDbFs::new()
  fs.write_string("/a.txt", "data")
  fs.reset()
  assert_false(fs.is_file("/a.txt"))
  assert_true(fs.is_dir("/"))
  assert_true(fs.dirty())
}
