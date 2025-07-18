const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const Stack = lib.collection.stack.ArrayStack;

pub fn TwoStacksQueue(T: type) type {
    return struct {
        pub const Item = T;
        const Queue = @This();

        inputs: Stack(Item),
        outputs: Stack(Item),

        pub fn init() Queue {
            return .{
                .inputs = Stack(Item).init(),
                .outputs = Stack(Item).init(),
            };
        }

        pub fn deinit(self: *Queue, a: Allocator) void {
            self.inputs.deinit(a);
            self.outputs.deinit(a);
        }

        pub fn size(self: Queue) usize {
            return self.inputs.size() + self.outputs.size();
        }

        pub fn enqueue(self: *Queue, a: Allocator, item: Item) Allocator.Error!void {
            try self.inputs.push(a, item);
        }

        pub fn dequeue(self: *Queue, a: Allocator) ?Item {
            self.transqueue(a);
            return self.outputs.pop();
        }

        pub fn peek(self: Queue, a: Allocator) ?Item {
            self.transqueue(a);
            return self.outputs.peek();
        }

        /// inputsからoutputsへ逆順で移し替える
        fn transqueue(self: *Queue, a: Allocator) void {
            if (self.outputs.size() == 0) {
                while (self.inputs.pop()) |item| {
                    self.outputs.push(a, item);
                }
            }
        }

        pub fn format(self: Queue, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("TwoStacksQueue{{", .{});

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

test TwoStacksQueue {
    const Queue = TwoStacksQueue(usize);
    const a = std.testing.allocator;
    const expect = lib.testing.expect;

    var stack = Queue.init();
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
