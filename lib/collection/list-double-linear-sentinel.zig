const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn DoubleLinearSentinelList(T: type) type {
    return struct {
        const List = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: *Node,
            prev: *Node,

            /// 値を持つノードのメモリを作成する。
            pub fn init(a: Allocator, value: T, next: *Node, prev: *Node) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = next, .prev = prev };
                return node;
            }

            /// このノードを削除してメモリを解放する。
            pub fn deinit(node: *Node, a: Allocator) void {
                if (node != ref_sentinel) {
                    a.destroy(node);
                }
            }

            /// ノードの値を返す。
            fn getValue(node: *const Node) ?T {
                return if (node != ref_sentinel) node.value else null;
            }

            pub fn format(node: *const Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                if (node == ref_sentinel) {
                    try writer.print("sentinel", .{});
                } else {
                    try writer.print("{{{}}} -> next", .{node.value});
                }
            }
        };

        var sentinel: Node = undefined;
        pub const ref_sentinel = &sentinel;

        head: *Node = ref_sentinel,

        /// 空のリストを作成する。
        pub fn init() List {
            return .{ .head = ref_sentinel };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            var node = self.head;

            while (node != ref_sentinel) {
                const next = node.next;
                a.destroy(node);
                node = next;
            }
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            var node = self.head;
            var count: usize = 0;
            while (node != ref_sentinel) : (node = node.next) {
                count += 1;
            }
            return count;
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            var node = self.head;

            while (node != ref_sentinel) {
                const next = node.next;
                a.destroy(node);
                node = next;
            }
            self.head = ref_sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) *Node {
            var count = index;
            var node = self.head;
            while (node != ref_sentinel and count != 0) : (node = node.next) {
                count -= 1;
            }
            return node;
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) *Node {
            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) *Node {
            var prev = ref_sentinel;
            var node = self.head;

            while (node != ref_sentinel) : (node = node.next) {
                prev = node;
            }

            return prev;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?T {
            return self.getNode(index).getValue();
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: List) ?T {
            return self.getFirstNode().getValue();
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: List) ?T {
            return self.getLastNode().getValue();
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) Allocator.Error!void {
            if (index == 0) return self.addFirst(a, value);

            const prev = self.getNode(index - 1);
            if (prev != ref_sentinel) {
                const next = prev.next;
                const node = try Node.init(a, value, next, prev);
                prev.next = node;
                next.prev = node;
            } else {
                // indexが範囲外の場合
                unreachable;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const next = self.head;
            const node = try Node.init(a, value, next, ref_sentinel);
            self.head = node;
            next.prev = node;
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const prev = self.getLastNode();
            const node = try Node.init(a, value, ref_sentinel, prev);
            prev.next = node;

            if (prev == ref_sentinel) {
                self.head = node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) void {
            if (index == 0) return self.removeFirst(a);

            const node = self.getNode(index - 1);
            if (node != ref_sentinel) {
                const target = node.next;
                node.next = target.next;
                target.deinit(a);
            } else unreachable;
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) void {
            const target = self.head;
            self.head = target.next;
            target.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) void {
            var prev_prev: *Node = ref_sentinel;
            var prev: *Node = ref_sentinel;
            var node: *Node = self.head;

            while (node != ref_sentinel) : (node = node.next) {
                prev_prev = prev;
                prev = node;
            }

            prev.deinit(a);
            if (prev_prev != ref_sentinel) {
                prev_prev.next = ref_sentinel;
            } else {
                self.head = ref_sentinel;
            }
        }

        /// リストを複製する。
        pub fn copy(self: List, a: Allocator) List {
            _ = .{ self, a };
        }

        pub const Iterator = struct {};

        pub fn iterator(self: List) Iterator {
            _ = self;
        }

        pub fn equal(left: List, right: List) bool {
            _ = left;
            _ = right;
        }

        pub fn format(self: List, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("List\n", .{});

            var node = self.head;
            var index: usize = 0;
            while (node != ref_sentinel) : (node = node.next) {
                try writer.print(" {d}: {}\n", .{ index, node });
                index += 1;
            }
        }
    };
}

test "list" {
    const List = DoubleLinearSentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == DoubleLinearSentinelList(u8));
    try lib.collection.testList(List, &list, a);
}
