//! 木構造
//! 

const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const Order = lib.math.Order;
const DynamicArray = lib.collection.dynamic_array.DynamicArray;
const Stack = lib.collection.stack.Stack;

/// AVL木
/// Adelson-Velskii and Landis' tree
/// Georgy Adelson-VelskyとEvgenii Landisによって考えられた、平衡二分探索木
pub fn AvlTree(T: type, compare_fn: fn (left: T, right: T) Order) type {
    return struct {
        pub const Value = T;

        pub const Node = struct {
            item: T,

            left: ?*Node = null,
            right: ?*Node = null,

            pub fn format(value: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
                _ = fmt;
                _ = options;

                try writer.print("{} -> left: {?}, right: {?}\n", .{
                    value.item,
                    if (value.left) |left| left.item else null,
                    if (value.right) |right| right.item else null,
                });
            }
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

        /// 木の高さを数える。
        /// ルートノードがない場合、0を返す。
        pub fn height(self: @This()) usize {
            return heightNode(self.root);
        }

        fn heightNode(node: ?*Node) usize {
            const nnode = node orelse return 0;

            const left = heightNode(nnode.left) + 1;
            const right = heightNode(nnode.right) + 1;
            return @max(left, right);
        }

        fn rotateLeftNode(node: *Node) void {
            var pivot = node.left orelse return; // なければ終了
            node.left = pivot.right;
            pivot.right = node;
            node.* = pivot.*;
        }

        fn rotateRightNode(node: *Node) void {
            var pivot = node.right orelse return; // なければ終了

            node.right = pivot.left;

            pivot.left = node;

            node.* = pivot.*;
        }

        test rotateRightNode {
            var n: Node = .{ .item = 1 };
            var ln: Node = .{ .item = 2 };
            var rn: Node = .{ .item = 3 };
            var lln: Node = .{ .item = 4 };
            var lrn: Node = .{ .item = 5 };
            var rln: Node = .{ .item = 6 };
            var rrn: Node = .{ .item = 7 };

            n.left = &ln;
            n.right = &rn;
            ln.left = &lln;
            ln.right = &lrn;
            rn.left = &rln;
            rn.right = &rrn;

            const n_ref = &n;

            try lib.assert.expectEqual(n_ref.item, 1);
            try lib.assert.expectEqual(n_ref.left.?.item, 2);
            try lib.assert.expectEqual(n_ref.right.?.item, 3);
            try lib.assert.expectEqual(n_ref.left.?.left.?.item, 4);
            try lib.assert.expectEqual(n_ref.left.?.right.?.item, 5);
            try lib.assert.expectEqual(n_ref.right.?.left.?.item, 6);
            try lib.assert.expectEqual(n_ref.right.?.right.?.item, 7);

            rotateRightNode(&n);

            try lib.assert.expectEqual(n_ref.item, 2);
            try lib.assert.expectEqual(n_ref.left.?.item, 4);
            try lib.assert.expectEqual(n_ref.right.?.item, 1);
            try lib.assert.expectEqual(n_ref.right.?.left.?.item, 5);
            try lib.assert.expectEqual(n_ref.right.?.right.?.item, 3);
            try lib.assert.expectEqual(n_ref.right.?.right.?.left.?.item, 6);
            try lib.assert.expectEqual(n_ref.right.?.right.?.right.?.item, 7);

            rotateLeftNode(&n);

            try lib.assert.expectEqual(n_ref.item, 1);
            try lib.assert.expectEqual(n_ref.left.?.item, 2);
            try lib.assert.expectEqual(n_ref.right.?.item, 3);
            try lib.assert.expectEqual(n_ref.left.?.left.?.item, 4);
            try lib.assert.expectEqual(n_ref.left.?.right.?.item, 5);
            try lib.assert.expectEqual(n_ref.right.?.left.?.item, 6);
            try lib.assert.expectEqual(n_ref.right.?.right.?.item, 7);
        }

        pub fn find(self: @This(), allocator: Allocator, item: Value) *Value {
            compare_fn;
            _ = self;
            _ = allocator;
            _ = item;
        }

        pub fn insert(self: *@This(), allocator: Allocator, item: Value) Allocator.Error!void {
            const new_node = try allocator.create(Node);
            new_node.* = .{
                .item = item,
            };

            if (self.root) |root| {
                _ = insertNode(root, new_node);
            } else {
                self.root = new_node;
            }
        }

        fn insertNode(node: *Node, new_node: *Node) void {
            const order = compare_fn(new_node.item, node.item);

            switch (order) {
                .less_than => {
                    if (node.left) |left| {
                        insertNode(left, new_node);
                    } else {
                        node.left = new_node;
                    }
                },
                .equal, .greater_than => {
                    if (node.right) |right| {
                        insertNode(right, new_node);
                    } else {
                        node.right = new_node;
                    }
                },
            }

            const left_height = heightNode(node.left);
            const right_height = heightNode(node.right);
            const diff = lib.math.absDiff(left_height, right_height);
            if (diff > 1) {
                if (left_height > right_height) {
                    const left = node.left orelse unreachable;
                    const left_left_height = heightNode(left.left);
                    const left_right_height = heightNode(left.right);
                    if (left_left_height < left_right_height) {
                        rotateLeftNode(left);
                    }

                    rotateRightNode(node);
                } else {
                    const right = node.right orelse unreachable;
                    const right_left_height = heightNode(right.left);
                    const right_right_height = heightNode(right.right);
                    if (right_left_height > right_right_height) {
                        rotateRightNode(right);
                    }

                    rotateLeftNode(node);
                }
            }
        }

        pub fn delete(self: *@This(), item: Value) void {
            _ = self;
            _ = item;
        }

        pub fn copyToSlice(self: @This(), allocator: Allocator) Allocator.Error![]const *Node {
            var array = lib.collection.dynamic_array.DynamicArray(*Node).init();
            defer array.deinit(allocator);

            var stack = Stack(*Node).init();
            defer stack.deinit(allocator);
            if (self.root) |root| {
                try stack.push(allocator, root);
            }

            while (stack.pop()) |node| {
                try array.push(allocator, node);

                if (node.left) |left| {
                    try stack.push(allocator, left);
                }
                if (node.right) |right| {
                    try stack.push(allocator, right);
                }
            }

            return array.copyToSlice(allocator);
        }

        const OuterThis = @This();
        pub const Iterator = struct {
            allocator: Allocator,
            stack: Stack(Value),

            pub fn next(self: *@This()) *const Value {
                _ = self;
            }
        };

        pub fn iterator(self: @This(), allocator: Allocator) Iterator {
            var stack = Stack(Value).init();
            if (self.root) |root| {
                stack.push(root);
            }

            return .{
                .allocator = allocator,
                .stack = stack,
            };
        }

        pub fn dump(self: @This(), allocator: Allocator) Allocator.Error!void {
            const slice = try self.copyToSlice(allocator);
            for (slice) |item| {
                std.debug.print("{}", .{item});
            }
            allocator.free(slice);
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
    try lib.assert.expectEqual(t.countRecursive(), 3);

    // try lib.assert.expectEqual(t.height(), 2);

}
