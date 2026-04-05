test "extract_tag_values" {
  let xml = "<Key>foo/bar.txt</Key><Key>baz.txt</Key>"
  let values = extract_tag_values(xml, "Key")
  assert_eq(values.length(), 2)
  assert_eq(values[0], "foo/bar.txt")
  assert_eq(values[1], "baz.txt")
}

test "extract_tag_values empty" {
  let values = extract_tag_values("<root></root>", "Key")
  assert_eq(values.length(), 0)
}

test "parse_list_objects_v2" {
  let xml =
    #|<?xml version="1.0" encoding="UTF-8"?>
    #|<ListBucketResult>
    #|  <Contents><Key>foo/bar.txt</Key><Size>42</Size></Contents>
    #|  <Contents><Key>baz/</Key><Size>0</Size></Contents>
    #|</ListBucketResult>
  let objects = parse_list_objects_v2(xml)
  assert_eq(objects.length(), 2)
  assert_eq(objects[0].key, "foo/bar.txt")
  assert_eq(objects[0].size, 42L)
  assert_eq(objects[1].key, "baz/")
  assert_eq(objects[1].size, 0L)
}
