const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const DynamicArray = lib.collection.dynamic_array.DynamicArray;

pub fn ArrayStack(T: type) type {
    return struct {
        pub const Item = T;
        const Array = DynamicArray(Item);
        const Stack = @This();

        values: Array,

        pub fn init() Stack {
            return .{ .values = Array.init() };
        }

        pub fn deinit(self: Stack, a: Allocator) void {
            self.values.deinit(a);
        }

        pub fn size(self: Stack) usize {
            return self.values.size();
        }

        pub fn push(self: *Stack, a: Allocator, item: Item) Allocator.Error!void {
            try self.values.pushBack(a, item);
        }

        pub fn pop(self: *Stack) ?Item {
            return self.values.popBack();
        }

        pub fn peek(self: Stack) ?*Item {
            if (self.size() == 0) return null;

            return self.values.getRef(self.size() - 1);
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
