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

fn copyInArray(slice: anytype, src: usize, dst: usize, length: usize) IndexError!void {
            const src_end = src + length;
            const dst_end = dst + length;

            if (src == dst or length == 0) return; // 何もしない場合
            if (!isInBoundRange(slice.len, .{ src, src_end })) return error.OutOfBounds;
            if (!isInBoundRange(slice.len, .{ dst, dst_end })) return error.OutOfBounds;

            const dst_slice = slice[dst..dst_end];
            const src_slice = slice[src..src_end];

            if (src_end < dst or dst_end < src) {
                @memcpy(dst_slice, src_slice);
            } else if (src < dst) {
                var i = dst_slice.len;
                while (i != 0) : (i -= 1) {
                    dst_slice[i - 1] = src_slice[i - 1];
                }
            } else {
                for (dst_slice, src_slice) |*d, s| {
                    d.* = s;
                }
            }
        }
