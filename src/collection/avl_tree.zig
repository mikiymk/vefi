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

            left: ?*Node = null,
            right: ?*Node = null,
        };

        root: ?*Node = null,
        pub fn init() @This() {
            return .{};
        }

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            deinitNode(allocator, self.root);
        }

        fn deinitNode(allocator: Allocator, node: ?*Node) void {
            if (node) |n| {
                deinitNode(allocator, n.left);
                deinitNode(allocator, n.right);
                allocator.destroy(n);
            }
        }

        pub fn count(self: @This(), allocator: Allocator) Allocator.Error!usize {
            var c: usize = 0;
            var stack = lib.collection.stack.Stack(*Node).init();
            defer stack.deinit(allocator);

            var node = self.root;
            while (node) |n| {
                c += 1;
                if (n.right) |r| {
                    try stack.push(allocator, r);
                }

                if (n.left) |l| {
                    node = l;
                } else {
                    node = stack.pop();
                }
            }

            return c;
        }

        pub fn countRecursive(self: @This()) usize {
            return countNode(self.root);
        }

        fn countNode(node: ?*Node) usize {
            if (node) |n| {
                return 1 + countNode(n.left) + countNode(n.right);
            } else {
                return 0;
            }
        }

        pub fn find(self: @This(), allocator: Allocator, item: T) *T {
            compare_fn;
            _ = self;
            _ = allocator;
            _ = item;
        }

        pub fn insert(self: *@This(), allocator: Allocator, item: T) Allocator.Error!void {
            const new_item = try allocator.create(Node);
            new_item.* = .{
                .item = item,
            };
            var node: ?*Node = undefined;

            if (self.root == null) {
                self.root = new_item;
                return;
            }
            node = self.root;

            while (node) |n| {
                const order = compare_fn(item, n.item);

                switch (order) {
                    .less_than => {
                        if (n.left == null) {
                            n.left = new_item;
                            return;
                        } else {
                            node = n.left;
                        }
                    },
                    .equal, .greater_than => {
                        if (n.right == null) {
                            n.right = new_item;
                            return;
                        } else {
                            node = n.right;
                        }
                    },
                }
            }
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

test AvlTree {
    const T = AvlTree(usize, struct {
        pub fn f(l: usize, r: usize) Order {
            if (l > r) return .greater_than;
            if (l > r) return .less_than;
            return .equal;
        }
    }.f);
    const a = std.testing.allocator;

    var t = T.init();
    defer t.deinit(a);

    try t.insert(a, 3);
    try t.insert(a, 4);
    try t.insert(a, 5);

    try lib.assert.expectEqual(t.count(a), 3);
}
