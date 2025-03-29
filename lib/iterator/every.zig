pub fn every(iterator: anytype) bool {
  while (iterator.next()) |value| {
    if (!value) {
      return false;
    }
  }
  return true;
}
