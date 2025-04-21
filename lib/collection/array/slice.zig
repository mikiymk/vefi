pub fn size(slice: anytype) usize {
 return slice.len;
}

pub fn isInBound(slice: anytype, index: usize) bool {
 const s = size(slice);

 return 0 <= index and index < s;
}

        pub fn isInBoundRange(slice: anytype, range: Range) bool {
            const begin, const end = range;
            const s = size(slice);

            return 0 <= begin and begin < s and
                0 < end and end <= s and
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

pub fn extendedSizeAtLeast(size: usize, min: usize) {
 if (min <= size) return size;
 var new_size = if (size == 0) initial_size else size;
 while (min <= new_size) {
  new_size *= extend_factor;
 }
 return new_size;
}
