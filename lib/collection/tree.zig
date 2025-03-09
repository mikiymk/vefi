//! 木構造
//!

const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;
const Optional = lib.types.Optional;
const Order = lib.math.Order;
const DynamicArray = lib.collection.DynamicArray;
const Stack = lib.collection.stack.Stack;

/// AVL木
/// Adelson-Velskii and Landis' tree
/// Georgy Adelson-VelskyとEvgenii Landisによって考えられた、平衡二分探索木
pub fn AvlTree(T: type, compare_fn: fn (left: T, right: T) Order) type {
    return struct {
        pub const Value = T;

        pub const Node = struct {
            item: T,

            left: ?*@This() = null,
            right: ?*@This() = null,

            /// 再帰的に部分木の破棄を行います。
            fn deinit(self: *@This(), allocator: Allocator) void {
                if (self.left) |left| {
                    left.deinit(allocator);
                    allocator.destroy(left);
                }

                if (self.right) |right| {
                    right.deinit(allocator);
                    allocator.destroy(right);
                }
            }

            /// 自身とその部分木のノード数を数えます。
            fn count(node: *Node) usize {
                var c: usize = 1;

                if (node.left) |left| c += left.count();
                if (node.right) |right| c += right.count();

                return c;
            }

            /// 自身から葉までの最長の距離を数えます。
            fn height(node: *Node) usize {
                const left = if (node.left) |left| left.height() else 0;
                const right = if (node.right) |right| right.height() else 0;

                return @max(left, right) + 1;
            }

            /// 平衡係数 = 左の部分木の高さ - 右の部分木の高さ。
            /// 左が高いと正の数、右が高いと負の数になる。
            fn balanceFactor(node: *Node) isize {
                const left = if (node.left) |left| left.height() else 0;
                const right = if (node.right) |right| right.height() else 0;

                return @bitCast(left -% right);
            }

            ///         a          b
            ///        / \        / \
            ///       b   C ->   A   a
            ///      / \            / \
            ///     A   B          B   C
            fn rotateRight(node: *Node) void {
                var a = node.*;
                const b_ref = a.left orelse return;
                var b = b_ref.*;

                a.left = b.right;
                b.right = b_ref;

                node.* = b;
                b_ref.* = a;
            }

            ///       a            b
            ///      / \          / \
            ///     A   b   ->   a   C
            ///        / \      / \
            ///       B   C    A   B
            fn rotateLeft(node: *Node) void {
                var a = node.*;
                const b_ref = a.right orelse return;
                var b = b_ref.*;

                a.right = b.left;
                b.left = b_ref;

                node.* = b;
                b_ref.* = a;
            }

            test rotateLeft {
                //      1
                //     / \
                //   2     3
                //  / \   / \
                // 4   5 6   7

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

                //      1               3
                //     / \             / \
                //   2     3   ->     1   7
                //  / \   / \        / \
                // 4   5 6   7      2   6
                //                 / \
                //                4   5
                rotateLeft(n_ref);

                try lib.assert.expectEqual(n_ref.item, 3);
                try lib.assert.expectEqual(n_ref.left.?.item, 1);
                try lib.assert.expectEqual(n_ref.right.?.item, 7);
                try lib.assert.expectEqual(n_ref.left.?.left.?.item, 2);
                try lib.assert.expectEqual(n_ref.left.?.right.?.item, 6);
                try lib.assert.expectEqual(n_ref.left.?.left.?.left.?.item, 4);
                try lib.assert.expectEqual(n_ref.left.?.left.?.right.?.item, 5);

                //       3           1
                //      / \         / \
                //     1   7 ->   2     3
                //    / \        / \   / \
                //   2   6      4   5 6   7
                //  / \
                // 4   5
                rotateRight(n_ref);

                try lib.assert.expectEqual(n_ref.item, 1);
                try lib.assert.expectEqual(n_ref.left.?.item, 2);
                try lib.assert.expectEqual(n_ref.right.?.item, 3);
                try lib.assert.expectEqual(n_ref.left.?.left.?.item, 4);
                try lib.assert.expectEqual(n_ref.left.?.right.?.item, 5);
                try lib.assert.expectEqual(n_ref.right.?.left.?.item, 6);
                try lib.assert.expectEqual(n_ref.right.?.right.?.item, 7);
            }

            /// ノードを挿入し、再バランスをとる。
            /// 再バランス操作が済んでいる場合、trueを返す。
            fn insert(node: *Node, new_node: *Node) bool {
                // 二分平衡木の挿入
                const order = compare_fn(new_node.item, node.item);

                switch (order) {
                    .less_than => {
                        if (node.left) |left| {
                            if (left.insert(new_node)) {
                                return true;
                            }
                        } else {
                            node.left = new_node;
                        }
                    },
                    .equal, .greater_than => {
                        if (node.right) |right| {
                            if (right.insert(new_node)) {
                                return true;
                            }
                        } else {
                            node.right = new_node;
                        }
                    },
                }

                // 再バランス
                const bf = node.balanceFactor();

                if (1 < bf) { // 左が2以上高い
                    const left = node.left orelse unreachable;

                    if (left.balanceFactor() < 0) {
                        left.rotateLeft();
                    }
                    node.rotateRight();

                    return true;
                } else if (bf < -1) { // 右が2以上高い
                    const right = node.right orelse unreachable;

                    if (right.balanceFactor() > 0) {
                        right.rotateRight();
                    }
                    node.rotateLeft();

                    return true;
                }

                return false;
            }

            fn delete(node: *Node, item: Value) bool {
                const order = compare_fn(item, node.item);

                switch (order) {
                    .equal => {},
                    .greater_than => {},
                    .less_than => {},
                }

                return false;
            }

            fn copyToSliceNode(node: *Node, allocator: Allocator, array: *DynamicArray(Value)) Allocator.Error!void {
                if (node.left) |left| {
                    try left.copyToSliceNode(allocator, array);
                }

                try array.pushBack(allocator, node.item);

                if (node.right) |right| {
                    try right.copyToSliceNode(allocator, array);
                }
            }

            /// 読みやすい文字列にフォーマットします。
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
            if (self.root) |root| {
                root.deinit(allocator);
                allocator.destroy(root);
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
            return if (self.root) |root| root.count() else 0;
        }

        /// 木の高さを数える。
        /// ルートノードがない場合、0を返す。
        pub fn height(self: @This()) usize {
            return if (self.root) |root| root.height() else 0;
        }

        pub fn find(self: @This(), allocator: Allocator, item: Value) *Value {
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
                _ = root.insert(new_node);
            } else {
                self.root = new_node;
            }
        }

        pub fn delete(self: *@This(), item: Value) void {
            if (self.root) |root| {
                _ = root.delete(item);
            }
        }

        pub fn copyToSlice(self: @This(), allocator: Allocator) Allocator.Error![]const Value {
            var array = DynamicArray(Value).init();
            defer array.deinit(allocator);

            if (self.root) |root| {
                try root.copyToSliceNode(allocator, &array);
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
    const T = AvlTree(usize, lib.common.compare(usize));
    const a = std.testing.allocator;

    var t = T.init();
    defer t.deinit(a);

    try t.insert(a, 3);
    try t.insert(a, 4);
    try t.insert(a, 5);

    try lib.assert.expectEqual(t.count(a), 3);
    try lib.assert.expectEqual(t.countRecursive(), 3);
    try lib.assert.expectEqual(t.height(), 2);

    try t.insert(a, 2);
    try t.insert(a, 1);

    try lib.assert.expectEqual(t.count(a), 5);
    try lib.assert.expectEqual(t.countRecursive(), 5);
    try lib.assert.expectEqual(t.height(), 3);

    const slice = try t.copyToSlice(a);
    defer a.free(slice);
    try lib.assert.expectEqual(slice, &.{ 1, 2, 3, 4, 5 });
}
