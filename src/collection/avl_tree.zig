const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const Order = lib.math.Order;

pub fn AvlTree(T: type, compare_fn: fn (left: T, right: T) Order) type {
    return struct {
        pub const Value = T;

        pub const Node = struct {
            item: T,

            left: ?*Node,
            right: ?*Node,
        };

        root: Node,

        pub fn count(self: @This(), allocator: Allocator) usize {
            _ = self;
            _ = allocator;
            compare_fn;
        }

        pub fn find(self: @This(), item: T) *T {
            _ = self;
            _ = item;
        }

        pub fn insert(self: *@This(), item: T) void {
            _ = self;
            _ = item;
        }

        pub fn delete(self: *@This(), item: T) void {
            _ = self;
            _ = item;
        }

        pub const Iterator = struct {};

        pub fn iterator(self: @This()) Iterator {
            _ = self;
        }
    };
}
