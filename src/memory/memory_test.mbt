async test "write and read file" {
  let fs = MemoryFs::new()
  fs.write_string("/hello.txt", "world")
  assert_eq(fs.read_string("/hello.txt"), "world")
}

async test "write creates parent dirs" {
  let fs = MemoryFs::new()
  fs.write_string("/a/b/c/file.txt", "deep")
  assert_true(fs.is_dir("/a"))
  assert_true(fs.is_dir("/a/b"))
  assert_true(fs.is_dir("/a/b/c"))
  assert_true(fs.is_file("/a/b/c/file.txt"))
}

async test "readdir lists files and dirs" {
  let fs = MemoryFs::new()
  fs.write_string("/repo/a.txt", "a")
  fs.write_string("/repo/b.txt", "b")
  fs.mkdir_p("/repo/sub")
  let entries = fs.readdir("/repo")
  assert_eq(entries.length(), 3)
  assert_true(entries.contains("a.txt"))
  assert_true(entries.contains("b.txt"))
  assert_true(entries.contains("sub"))
}

async test "remove_file" {
  let fs = MemoryFs::new()
  fs.write_string("/tmp/x.txt", "data")
  assert_true(fs.is_file("/tmp/x.txt"))
  fs.remove_file("/tmp/x.txt")
  assert_false(fs.is_file("/tmp/x.txt"))
}

async test "remove_file not found raises" {
  let fs = MemoryFs::new()
  let mut raised = false
  try {
    fs.remove_file("/nonexistent")
  } catch {
    @vfs.VfsError(_) => raised = true
  }
  assert_true(raised)
}

async test "read_file not found raises" {
  let fs = MemoryFs::new()
  let mut raised = false
  try {
    let _ = fs.read_file("/nonexistent")
  } catch {
    @vfs.VfsError(_) => raised = true
  }
  assert_true(raised)
}

async test "readdir on nonexistent dir raises" {
  let fs = MemoryFs::new()
  let mut raised = false
  try {
    let _ = fs.readdir("/nope")
  } catch {
    @vfs.VfsError(_) => raised = true
  }
  assert_true(raised)
}

async test "is_dir root exists" {
  let fs = MemoryFs::new()
  assert_true(fs.is_dir("/"))
}

async test "reset clears all" {
  let fs = MemoryFs::new()
  fs.write_string("/a.txt", "data")
  fs.mkdir_p("/sub")
  fs.reset()
  assert_false(fs.is_file("/a.txt"))
  assert_false(fs.is_dir("/sub"))
  assert_true(fs.is_dir("/"))
}

async test "snapshot export and import" {
  let fs1 = MemoryFs::new()
  fs1.write_string("/repo/README.md", "# Hello")
  fs1.write_string("/repo/src/main.mbt", "fn main {}")
  let snapshot = fs1.export_snapshot()
  let fs2 = MemoryFs::new()
  fs2.replace_snapshot(snapshot)
  assert_eq(fs2.read_string("/repo/README.md"), "# Hello")
  assert_eq(fs2.read_string("/repo/src/main.mbt"), "fn main {}")
  assert_true(fs2.is_dir("/repo/src"))
}
