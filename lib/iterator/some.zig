pub fn some(iterator: anytype) bool {
  while (iterator.next()) |value| {
    if (value) {
      return true;
    }
  }
  return false;
}
