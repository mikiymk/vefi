const std = @import("std");
const lib = @import("../root.zig");

const assert = lib.assert.assert;
const Range = lib.collection.array.Range;

pub fn StaticArrayOptions(T: type) type {
    return struct {
        comptime sentinel: ?T = null,
    };
}

/// 静的配列 (Static Array)
pub fn StaticArray(T: type, array_size: usize, comptime options: StaticArrayOptions(T)) type {
    const Array = if (options.sentinel) |sentinel|
        [array_size:sentinel]T
    else
        [array_size]T;

    return struct {
        _values: Array,

        pub fn init(initial_value: T) @This() {
            var array = @This(){ ._values = undefined };
            array.fill(0, array.size(), initial_value);

            return array;
        }

        pub fn deinit(self: @This()) void {
            _ = self;
        }

        pub fn isInBoundIndex(self: @This(), index: usize) bool {
            return 0 <= index and index < self.size();
        }

        pub fn isInBoundRange(self: @This(), range: Range) bool {
            return 0 <= range.begin and
                range.begin < self.size() and
                0 < range.end and
                range.end <= self.size() and
                range.begin < range.end;
        }

        pub fn size(self: @This()) usize {
            return self._values.len;
        }

        pub fn get(self: @This(), index: usize) T {
            assert(self.isInBoundIndex(index));

            return self._values[index];
        }

        pub fn getRef(self: *@This(), index: usize) *T {
            assert(self.isInBoundIndex(index));

            return &self._values[index];
        }

        pub fn set(self: *@This(), index: usize, value: T) void {
            assert(self.isInBoundIndex(index));

            self._values[index] = value;
        }

        pub fn fill(self: *@This(), begin: usize, end: usize, value: T) void {
            assert(self.isInBoundRange(.{ .begin = begin, .end = end }));

            @memset(self._values[begin..end], value);
        }

        pub fn swap(self: *@This(), left: usize, right: usize) void {
            assert(self.isInBoundIndex(left));
            assert(self.isInBoundIndex(right));

            const tmp = self.get(left);
            self.set(left, self.get(right));
            self.set(right, tmp);
        }

        pub fn reverse(self: *@This()) void {
            for (0..(self.size() / 2)) |i| {
                self.swap(i, self.size() - i - 1);
            }
        }
    };
}

test StaticArray {
    const Array = StaticArray(usize, 5, .{});
    const equals = lib.assert.expectEqual;

    var array = Array.init(0);
    try equals(array._values, .{ 0, 0, 0, 0, 0 });

    array.set(0, 1);
    try equals(array._values, .{ 1, 0, 0, 0, 0 });
    try equals(array.get(0), 1);

    const ptr = array.getRef(4);
    ptr.* = 2;
    try equals(array._values, .{ 1, 0, 0, 0, 2 });

    array.fill(1, 3, 4);
    try equals(array._values, .{ 1, 4, 4, 0, 2 });

    array.swap(2, 4);
    try equals(array._values, .{ 1, 4, 2, 0, 4 });

    array.reverse();
    try equals(array._values, .{ 4, 0, 2, 4, 1 });
}
