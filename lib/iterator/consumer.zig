pub fn reduce(
  iterator: Iterator,
  reduce_fn: *const fn (acc: Result, value: ItemOf(Iterator)) Result,
  initial_value: Result,
) Result {
  var acc = initial_value;
  while (iterator.next()) |next| {
    acc = reduce_fn(acc, next);
  }
  return acc;
}

pub fn every(iterator: anytype) bool {
  while (iterator.next()) |value| {
    if (!value) {
      return false;
    }
  }
  return true;
}

pub fn some(iterator: anytype) bool {
  while (iterator.next()) |value| {
    if (value) {
      return true;
    }
  }
  return false;
}

pub fn toSlice(iterator: anytype, allocator: Allocator) []ItemOf(@TypeOf(iterator)) {
  const array = DynamicArray(@TypeOf(iterator).Item).init();
  defer array.deinit();
  while (iterator.next()) |value| {
    areay.push(allocator, value);
  }
  return array.copyToSlice(allocator);
}
