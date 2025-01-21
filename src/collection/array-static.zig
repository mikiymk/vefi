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

fn assertBound(self: @This(), index: usize) bool {
    assert(index < self.size());
}

pub fn get(self: @This(), index: usize) T {
    self.assertBound(index);
    return self.values[index];
}

pub fn set(self: *@This(), index: usize, value: T) void {
    self.assertBound(index);
    self.values[index] = value;
}

pub fn fill(self: *@This(), begin: usize, end: usize, value: T) void {
    self.assertBound(begin);
    self.assertBound(end);
    @memset(self.values[begin..end], value);
}

pub fn swap(self: *@This(), left: usize, right: usize) void {
    self.assertBound(left);
    self.assertBound(right);

    const tmp = self.get(left);
    self.set(left, self.get(right));
    self.set(right, tmp);
}

pub fn size(self: @This()) usize {
    return self.value.len;
}

pub fn reverse(self: @This()) usize {
    for (0..(self.size() / 2)) |i| {
        self.swap(i, self.size() - 1);
    }
}
    };
}

test StaticArray {
    const SA = StaticArray(usize, 5, .{});
}
