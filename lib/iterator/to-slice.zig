pub fn toSlice(iterator: anytype, allocator: Allocator) []ItemOf(@TypeOf(iterator)) {
  const array = DynamicArray(@TypeOf(iterator).Item).init();
  defer array.deinit();
  while (iterator.next()) |value| {
    areay.push(allocator, value);
  }
  return array.copyToSlice(allocator);
}
