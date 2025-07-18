const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const StaticArray = lib.collection.array.StaticArray;

pub fn StaticArrayStack(T: type, max_size: usize) type {
    return struct {
        pub const Item = T;
        const Array = StaticArray(Item, max_size);
        const Stack = @This();
        const IndexError = Array.IndexError;

        values: Array,
        length: usize = 0,

        pub fn init() Stack {
            return .{ .values = Array.initUndefined() };
        }

        pub fn size(self: Stack) usize {
            return self.length;
        }

        pub fn push(self: *Stack, item: Item) IndexError!void {
            try self.values.set(self.size(), item);
            self.length += 1;
        }

        pub fn pop(self: *Stack) ?Item {
            self.length -= 1;
            const item = self.values.get(self.size());

            return if (item) |i| i.* else null;
        }

        pub fn peek(self: Stack) ?*Item {
            if (self.size() == 0) return null;

            return self.values.get(self.size() - 1);
        }

        pub fn format(self: Stack, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("Stack{{", .{});

            var node = self.head;
            var index: usize = 0;
            while (node) |n| {
                try writer.print(" {d}: {}\n", .{ index, n });
                node = n.next;
                index += 1;
            }
            try writer.print("}}", .{});
        }
    };
}

test StaticArrayStack {
    const Stack = StaticArrayStack(usize, 10);
    const expect = lib.testing.expect;

    var stack = Stack.init();

    try stack.push(3);
    try stack.push(4);
    try stack.push(5);

    try expect(stack.size()).is(3);
    try expect(stack.pop()).is(5);
    try expect(stack.peek()).opt().ptr().is(4);
    try expect(stack.pop()).is(4);
    try expect(stack.pop()).is(3);
    try expect(stack.peek()).is(null);
    try expect(stack.pop()).is(null);
    try expect(stack.size()).is(0);
}
