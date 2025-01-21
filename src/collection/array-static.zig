const std = @import("std");
const lib = @import("../root.zig");

const StaticArrayOptions = struct {
};

/// 静的配列 (Static Array)
pub fn StaticArray(T: type, size: usize, comptime options: StaticArrayOptions) type {
    return struct {
        values: [size]T,

pub fn init() @This() {}

pub fn deinit(self: @This()) void {}

fn checkBound(self: @This(), index: usize) bool {
    return index < self.values.len;
}

pub fn getUnsafe(self: @This(), index: usize) T {
    assert(self.checkBound(index));
    return self.values[index];
}

pub fn get(self: @This(), index: usize) Error!T {
    if (self.checkBound(index)) return error.OutOfIndex;
    return self.getUnsafe(index);
}

pub fn setUnsafe(self: *@This(), index: usize, value: T) void {
    assert(self.checkBound(index));
    self.values[index] = value;
}

pub fn set(self: *@This(), index: usize, value: T) Error!T {
    if (self.checkBound(index)) return error.OutOfIndex;
    return self.setUnsafe(index, value);
}
    };
}

test StaticArray {
    const SA = StaticArray(usize, 5, .{});
}
