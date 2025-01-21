const std = @import("std");
const lib = @import("../root.zig");

const Allocator = lib.allocator.Allocator;
const AllocatorError = lib.allocator.AllocatorError;

const StaticArrayOptions = struct {
};

/// 静的配列 (Static Array)
pub fn StaticArray(T: type, size: usize, comptime options: StaticArrayOptions) type {
    return struct {
        value: [size]T,
    };
}

test StaticArray {
    const SA = StaticArray(usize, 5, .{});
}
