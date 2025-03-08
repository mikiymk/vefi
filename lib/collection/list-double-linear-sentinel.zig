const std = @import("std");
const lib = @import("../root.zig");
const list_util = @import("list.zig");

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
                a.destroy(node);
            }

            /// ノードの値を返す。
            fn getValue(node: *const Node, sentinel: *const Node) ?T {
                return if (node != sentinel) node.value else null;
            }

            pub fn format(node: *const Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                try writer.print("{}", .{node.value});
            }
        };

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: *Node,
        tail: *Node,
        sentinel: *Node,

        /// 空のリストを作成する。
        pub fn init(a: Allocator) Allocator.Error!List {
            var sentinel = try Node.init(a, undefined, undefined, undefined);
            sentinel.next = sentinel;
            sentinel.prev = sentinel;

            return .{ .head = sentinel, .tail = sentinel, .sentinel = sentinel };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            var node = self.head;

            while (node != self.sentinel) {
                const next = node.next;
                node.deinit(a);
                node = next;
            }

            self.sentinel.deinit(a);
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            return list_util.sizeSentinel(self.head, self.sentinel);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            list_util.clearSentinel(a, self.head, self.sentinel);
            self.head = self.sentinel;
            self.tail = self.sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) *Node {
            return list_util.getNodeSentinel(self.head, self.sentinel, index);
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) *Node {
            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) *Node {
            return self.tail;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?T {
            return self.getNode(index).getValue(self.sentinel);
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: List) ?T {
            return self.getFirstNode().getValue(self.sentinel);
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: List) ?T {
            return self.getLastNode().getValue(self.sentinel);
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) AllocIndexError!void {
            if (index == 0) return self.addFirst(a, value);

            const prev = self.getNode(index - 1);
            if (prev == self.sentinel) return error.OutOfBounds;

            const next = prev.next;
            const node = try Node.init(a, value, next, prev);
            prev.next = node;
            next.prev = node;
            if (next == self.sentinel) {
                self.tail = node;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const next = self.head;
            const node = try Node.init(a, value, next, self.sentinel);

            next.prev = node;

            self.head = node;
            if (next == self.sentinel) {
                self.tail = node;
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const prev = self.getLastNode();
            const node = try Node.init(a, value, self.sentinel, prev);

            prev.next = node;

            if (prev == self.sentinel) {
                self.head = node;
            }
            self.tail = node;
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            const node = self.getNode(index);
            if (node == self.sentinel) return error.OutOfBounds;

            const prev = node.prev;
            const next = node.next;

            node.deinit(a);
            if (prev == self.sentinel) {
                self.head = next;
            } else {
                prev.next = next;
            }
            if (next == self.sentinel) {
                self.tail = prev;
            } else {
                next.prev = prev;
            }
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) IndexError!void {
            const node = self.head;
            const next = node.next;
            if (node == self.sentinel) return error.OutOfBounds;

            node.deinit(a);
            self.head = next;
            next.prev = self.sentinel;
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            const node = self.tail;
            const prev = node.prev;
            if (node == self.sentinel) return error.OutOfBounds;

            node.deinit(a);
            self.tail = prev;
            prev.next = self.sentinel;
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
            const type_name = "DoubleLinearSentinelList(" ++ @typeName(T) ++ ")";

            try list_util.formatSentinel(w, type_name, self.head, self.sentinel);
        }
    };
}

test DoubleLinearSentinelList {
    const List = DoubleLinearSentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = try List.init(a);
    defer list.deinit(a);

    try expect(@TypeOf(list) == DoubleLinearSentinelList(u8));
    try lib.collection.testList(List, &list, a);
}

test "format" {
    const List = DoubleLinearSentinelList(u8);
    const a = std.testing.allocator;

    var list = try List.init(a);
    defer list.deinit(a);

    try list.addLast(a, 1);
    try list.addLast(a, 2);
    try list.addLast(a, 3);
    try list.addLast(a, 4);
    try list.addLast(a, 5);

    const format = try std.fmt.allocPrint(a, "{}", .{list});
    defer a.free(format);

    try lib.assert.expectEqualString("DoubleLinearSentinelList(u8){ 1, 2, 3, 4, 5 }", format);
}
