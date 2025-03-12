pub const StaticMultiDimensionalArrayOptions = struct {};

/// 静的多次元配列 (Static Multi-Dimensional Array)
pub fn StaticMultiDimensionalArray(T: type, comptime dimension: usize, sizes: [dimension]usize) type {
    return struct {
        pub const Indexes = [dimension]usize;
        const length: usize = blk: {
            var l: usize = 1;
            for (sizes) |size| {
                l *= size;
            }
            break :blk l;
        };
        value: [length]T,

         fn getRawIndex(indexes: Indexes) usize {
            var index: usize = 0;

            for (sizes, indexes) |size, i| {
                 index = index * size + i;
            }

             return index; 
        }

        pub fn size (self: @This())usize { return length; }
    };
}
