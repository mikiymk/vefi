const std = @import("std");
const lib = @import("../root.zig");

const assert = lib.assert.assert;

pub const StaticArrayOptions = struct {};

/// 静的配列 (Static Array)
pub fn StaticArray(T: type, array_size: usize, comptime options: StaticArrayOptions) type {
    _ = options;

    return struct {
        values: [array_size]T,

        pub fn init(initial_value: T) @This() {
            var array = @This(){ .values = undefined };
            array.fill(0, array.size(), initial_value);

            return array;
        }

        pub fn deinit(self: @This()) void {
            _ = self;
        }

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
            assert(end <= self.size());
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
    const eq = lib.assert.expectEqual;

    var array = SA.init(0);
    try eq(array.values, .{ 0, 0, 0, 0, 0 });

    array.set(0, 1);
    try eq(array.values, .{ 1, 0, 0, 0, 0 });
    try eq(array.get(0), 1);

    array.fill(1, 3, 4);
    try eq(array.values, .{ 1, 4, 4, 4, 0 });

    array.swap(2, 4);
    try eq(array.values, .{ 1, 4, 0, 4, 4 });

    array.reverse();
    try eq(array.values, .{ 4, 4, 0, 4, 1 });
}
