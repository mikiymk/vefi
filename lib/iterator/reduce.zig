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
