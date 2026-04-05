///|
test "write and read file" {
  let fs = SqliteFs::in_memory()
  fs.write_string("/hello.txt", "world")
  assert_eq(fs.read_string("/hello.txt"), "world")
}

///|
test "write creates parent dirs" {
  let fs = SqliteFs::in_memory()
  fs.write_string("/a/b/c/file.txt", "deep")
  assert_true(fs.is_dir("/a"))
  assert_true(fs.is_dir("/a/b"))
  assert_true(fs.is_dir("/a/b/c"))
  assert_true(fs.is_file("/a/b/c/file.txt"))
}

///|
test "readdir lists files and dirs" {
  let fs = SqliteFs::in_memory()
  fs.write_string("/repo/a.txt", "a")
  fs.write_string("/repo/b.txt", "b")
  fs.mkdir_p("/repo/sub")
  let entries = fs.readdir("/repo")
  assert_eq(entries.length(), 3)
  assert_true(entries.contains("a.txt"))
  assert_true(entries.contains("b.txt"))
  assert_true(entries.contains("sub"))
}

///|
test "remove_file" {
  let fs = SqliteFs::in_memory()
  fs.write_string("/tmp/x.txt", "data")
  assert_true(fs.is_file("/tmp/x.txt"))
  fs.remove_file("/tmp/x.txt")
  assert_false(fs.is_file("/tmp/x.txt"))
}

///|
test "remove_file not found raises" {
  let fs = SqliteFs::in_memory()
  let mut raised = false
  fs.remove_file("/nonexistent") catch {
    @vfs.VfsError(_) => raised = true
  }
  assert_true(raised)
}

///|
test "read_file not found raises" {
  let fs = SqliteFs::in_memory()
  let mut raised = false
  try {
    let _ = fs.read_file("/nonexistent")
  } catch {
    @vfs.VfsError(_) => raised = true
  }
  assert_true(raised)
}

///|
test "readdir on nonexistent dir raises" {
  let fs = SqliteFs::in_memory()
  let mut raised = false
  try {
    let _ = fs.readdir("/nope")
  } catch {
    @vfs.VfsError(_) => raised = true
  }
  assert_true(raised)
}

///|
test "is_dir root exists" {
  let fs = SqliteFs::in_memory()
  assert_true(fs.is_dir("/"))
}

///|
test "remove_dir recursive" {
  let fs = SqliteFs::in_memory()
  fs.write_string("/a/b/c.txt", "data")
  fs.write_string("/a/d.txt", "data2")
  fs.remove_dir("/a")
  assert_false(fs.is_dir("/a"))
  assert_false(fs.is_dir("/a/b"))
  assert_false(fs.is_file("/a/b/c.txt"))
  assert_false(fs.is_file("/a/d.txt"))
}

///|
test "snapshot export and import" {
  let fs1 = SqliteFs::in_memory()
  fs1.write_string("/repo/README.md", "# Hello")
  fs1.write_string("/repo/src/main.mbt", "fn main {}")
  let snapshot = fs1.export_snapshot()
  let fs2 = SqliteFs::in_memory()
  fs2.replace_snapshot(snapshot)
  assert_eq(fs2.read_string("/repo/README.md"), "# Hello")
  assert_eq(fs2.read_string("/repo/src/main.mbt"), "fn main {}")
  assert_true(fs2.is_dir("/repo/src"))
}

///|
test "overwrite file" {
  let fs = SqliteFs::in_memory()
  fs.write_string("/test.txt", "v1")
  assert_eq(fs.read_string("/test.txt"), "v1")
  fs.write_string("/test.txt", "v2")
  assert_eq(fs.read_string("/test.txt"), "v2")
}

///|
test "mkdir_p idempotent" {
  let fs = SqliteFs::in_memory()
  fs.mkdir_p("/a/b/c")
  fs.mkdir_p("/a/b/c")
  assert_true(fs.is_dir("/a/b/c"))
}
