pub fn isInBound(size: usize, index: usize) bool {
 return 0 <= index and index < size;
}

pub fn isInBoundRange(size: usize, range: Range) bool {
 const begin, const end = range;

 return 0 <= begin and begin < size and
  0 < end and end <= size and
  begin < end;
}

pub const initial_size = 8;
pub const extend_factor = 2;

pub fn extendedSize(size: usize) usize {
 if (size == 0) {
  return initial_size;
 }
 return size * extend_factor;
}

pub fn extendedSizeAtLeast(size: usize, min_size: usize) {
 var new_size = if (size == 0) initial_size else size;
 while (min_size <= new_size) {
  new_size *= extend_factor;
 }
 return new_size;
}
