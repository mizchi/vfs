///|
async test "RealFs write and read file" {
  @async.with_task_group(root => {
    let tmp = @fs.tmpdir(prefix="vfs-realfs-test")
    root.add_defer(() => @fs.rmdir(tmp, recursive=true))
    let fs = @realfs.RealFs::new(tmp)
    fs.write_string("/hello.txt", "world")
    let data = fs.read_file("/hello.txt")
    assert_eq(data, b"world")
  })
}

///|
async test "RealFs mkdir_p and readdir" {
  @async.with_task_group(root => {
    let tmp = @fs.tmpdir(prefix="vfs-realfs-test")
    root.add_defer(() => @fs.rmdir(tmp, recursive=true))
    let fs = @realfs.RealFs::new(tmp)
    fs.mkdir_p("/a/b/c")
    fs.write_string("/a/b/c/file.txt", "content")
    let entries = fs.readdir("/a/b/c")
    assert_eq(entries, ["file.txt"])
    let entries_a = fs.readdir("/a")
    assert_eq(entries_a, ["b"])
  })
}

///|
async test "RealFs is_dir and is_file" {
  @async.with_task_group(root => {
    let tmp = @fs.tmpdir(prefix="vfs-realfs-test")
    root.add_defer(() => @fs.rmdir(tmp, recursive=true))
    let fs = @realfs.RealFs::new(tmp)
    fs.mkdir_p("/mydir")
    fs.write_string("/mydir/test.txt", "data")
    assert_true(fs.is_dir("/mydir"))
    assert_false(fs.is_file("/mydir"))
    assert_true(fs.is_file("/mydir/test.txt"))
    assert_false(fs.is_dir("/mydir/test.txt"))
    assert_false(fs.is_file("/nonexistent"))
    assert_false(fs.is_dir("/nonexistent"))
  })
}

///|
async test "RealFs remove_file" {
  @async.with_task_group(root => {
    let tmp = @fs.tmpdir(prefix="vfs-realfs-test")
    root.add_defer(() => @fs.rmdir(tmp, recursive=true))
    let fs = @realfs.RealFs::new(tmp)
    fs.write_string("/removeme.txt", "bye")
    assert_true(fs.is_file("/removeme.txt"))
    fs.remove_file("/removeme.txt")
    assert_false(fs.is_file("/removeme.txt"))
  })
}

///|
async test "RealFs remove_dir" {
  @async.with_task_group(root => {
    let tmp = @fs.tmpdir(prefix="vfs-realfs-test")
    root.add_defer(() => @fs.rmdir(tmp, recursive=true))
    let fs = @realfs.RealFs::new(tmp)
    fs.mkdir_p("/dir/sub")
    fs.write_string("/dir/sub/f.txt", "nested")
    fs.remove_dir("/dir")
    assert_false(fs.is_dir("/dir"))
  })
}

///|
async test "RealFs export_snapshot and replace_snapshot" {
  @async.with_task_group(root => {
    let tmp = @fs.tmpdir(prefix="vfs-realfs-test")
    root.add_defer(() => @fs.rmdir(tmp, recursive=true))
    let fs = @realfs.RealFs::new(tmp)
    fs.mkdir_p("/snap/dir")
    fs.write_string("/snap/dir/a.txt", "aaa")
    fs.write_string("/snap/b.txt", "bbb")
    let snapshot = fs.export_snapshot()
    // Replace with a different snapshot
    let new_snap = @vfs.snapshot(["/", "/other"], [
      @vfs.snapshot_file("/other/c.txt", b"ccc"),
    ])
    fs.replace_snapshot(new_snap)
    assert_false(fs.is_dir("/snap"))
    assert_true(fs.is_dir("/other"))
    let data = fs.read_file("/other/c.txt")
    assert_eq(data, b"ccc")
    // Restore original
    fs.replace_snapshot(snapshot)
    assert_true(fs.is_dir("/snap/dir"))
  })
}
