const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const AllocatorError = lib.allocator.AllocatorError;

// 配列の関数
// get set
// size clear
// indexOf
// sort reverse

// 動的配列
// pushFront pushBack popFront popBack
// concat slice

// 配列の種類
// 静的・動的
// 線形・環状

const ArrayOptions = struct {
    dynamic: bool,
    max_length: ?usize,
};

pub const static_array = @import("./array-static.zig");
pub const dynamic_array = @import("./array-dynamic.zig");

const StaticMultiDimensionalArrayOptions = struct {};
/// 静的多次元配列 (Static Multi-Dimensional Array)
pub fn StaticMultiDimensionalArray(T: type, dimension: usize, sizes: [dimension]usize, comptime options: StaticMultiDimensionalArrayOptions) type {
    _ = options;
    _ = sizes;
    _ = T;
    return struct {
        // value: [size]T,
    };
}
