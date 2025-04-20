pub fn size(slice: anytype) usize {
 return slice.len;
}

pub const initial_size = 8;
pub const extend_factor = 2;

pub fn extendedSize(size: usize) usize {
 if (size == 0) {
  return initial_size;
 }
 return size * extend_factor;
}

pub fn extendedSizeAtLeast(size: usize, min: usize) {
 if (min <= size) return size;
 var new_size = if (size == 0) initial_size else size;
 while (min <= new_size) {
  new_size *= extend_factor;
 }
 return new_size;
}
