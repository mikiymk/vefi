const std = @import("std");
const lib = @import("../../root.zig");

/// 静的多次元配列 (Static Multi-Dimensional Array)
pub fn StaticMultiDimensionalArray(T: type, comptime dimension: usize, sizes: [dimension]usize) type {
    return struct {
        pub const Indexes = [dimension]usize;
        const length: usize = blk: {
            var l: usize = 1;
            for (sizes) |s| {
                l *= s;
            }
            break :blk l;
        };
        value: [length]T,

        fn getRawIndex(indexes: Indexes) usize {
            var index: usize = 0;

            for (sizes, indexes) |s, i| {
                index = index * s + i;
            }

            return index;
        }

        pub fn size(self: @This()) usize {
            _ = self;
            return length;
        }
    };
}
