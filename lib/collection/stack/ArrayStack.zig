const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const DynamicArray = lib.collection.array.DynamicArray;

pub fn ArrayStack(T: type) type {
    return struct {
        pub const Item = T;
        const Array = DynamicArray(Item);
        const Stack = @This();

        values: Array,

        pub fn init() Stack {
            return .{ .values = Array.init() };
        }

        pub fn deinit(self: *Stack, a: Allocator) void {
            self.values.deinit(a);
        }

        pub fn size(self: Stack) usize {
            return self.values.size();
        }

        pub fn push(self: *Stack, a: Allocator, item: Item) Allocator.Error!void {
            try self.values.addLast(a, item);
        }

        pub fn pop(self: *Stack) ?Item {
            return self.values.removeLast();
        }

        pub fn peek(self: Stack) ?Item {
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

test ArrayStack {
    const Stack = ArrayStack(usize);
    const a = std.testing.allocator;
    const expect = lib.testing.expect;

    var stack = Stack.init();
    defer stack.deinit(a);

    try stack.push(a, 3);
    try stack.push(a, 4);
    try stack.push(a, 5);

    try expect(stack.size()).is(3);
    try expect(stack.pop()).is(5);
    try expect(stack.peek()).is(4);
    try expect(stack.pop()).is(4);
    try expect(stack.pop()).is(3);
    try expect(stack.peek()).is(null);
    try expect(stack.pop()).is(null);
    try expect(stack.size()).is(0);
}
