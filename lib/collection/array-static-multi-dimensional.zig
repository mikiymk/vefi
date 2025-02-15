pub const StaticMultiDimensionalArrayOptions = struct {};

/// 静的多次元配列 (Static Multi-Dimensional Array)
pub fn StaticMultiDimensionalArray(T: type, comptime dimension: usize, sizes: [dimension]usize, comptime options: StaticMultiDimensionalArrayOptions) type {
    _ = options;

    return struct {
        pub const Indexes = [dimension]usize;
        pub const length: usize = blk: {
            var l: usize = 1;
            for (sizes) |size| {
                l *= size;
            }
            break :blk l;
        };
        value: [length]T,
    };
}
