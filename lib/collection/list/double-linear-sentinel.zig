const std = @import("std");
const lib = @import("../root.zig");
const generic_list = lib.collection.generic_list_sentinel;

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
                const node = try a.create(Node);
                node.* = .{ .value = value, .next = next, .prev = prev };
                return node;
            }

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            pub fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node = try a.create(Node);
                node.* = .{ .value = value, .next = node, .prev = node };
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
            var sentinel = try a.create(Node);
            sentinel.next = sentinel;
            sentinel.prev = sentinel;

            return .{ .head = sentinel, .tail = sentinel, .sentinel = sentinel };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            generic_list.clear(a, self.head, self.sentinel);
            self.sentinel.deinit(a);
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: List) bool {
            var prev = self.sentinel;
            var node = self.head;
            while (node != self.sentinel) : (node = node.next) {
                if (node.prev != prev) return false;
                prev = node;
            }

            if (self.sentinel.next != self.sentinel) return false;
            if (self.sentinel.prev != self.sentinel) return false;
            return true;
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            assert(self.isValidList());

            return generic_list.size(self.head, self.sentinel);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            generic_list.clear(a, self.head, self.sentinel);
            self.head = self.sentinel;
            self.tail = self.sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) *Node {
            assert(self.isValidList());

            return generic_list.getNode(self.head, self.sentinel, index);
        }

        /// リストの指定した位置のノードを返す。
        fn getNodeFromLast(self: List, index: usize) *Node {
            assert(self.isValidList());

            var node = self.tail;
            var count = index;

            while (node != self.sentinel and count != 0) : (node = node.prev) {
                count -= 1;
            }
            return node;
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) *Node {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) *Node {
            assert(self.isValidList());

            return self.tail;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?T {
            return self.getNode(index).getValue(self.sentinel);
        }

        /// リストの最後から指定した位置の要素を返す。
        pub fn getFromLast(self: List, index: usize) ?T {
            return self.getNodeFromLast(index).getValue(self.sentinel);
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
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.addFirst(a, value);
            }

            const prev = self.getNode(index - 1);
            if (prev == self.sentinel) return error.OutOfBounds;
            const next = prev.next;
            const node = try Node.init(a, value, next, prev);

            prev.next = node;
            if (next == self.sentinel) {
                self.tail = node;
            } else {
                next.prev = node;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const next = self.head;
            const node = try Node.init(a, value, next, self.sentinel);

            self.head = node;
            if (next == self.sentinel) {
                self.tail = node;
            } else {
                next.prev = node;
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const prev = self.getLastNode();
            const node = try Node.init(a, value, self.sentinel, prev);

            if (prev == self.sentinel) {
                self.head = node;
            } else {
                prev.next = node;
            }
            self.tail = node;
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.getNode(index);
            const prev = node.prev;
            const next = node.next;
            if (node == self.sentinel) return error.OutOfBounds;

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
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.head;
            const next = node.next;
            if (node == self.sentinel) return error.OutOfBounds;

            node.deinit(a);
            self.head = next;
            next.prev = self.sentinel;
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

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
            try generic_list.format(w, type_name, self.head, self.sentinel);
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
    try lib.collection.test_list.testList(List, &list, a);
    try lib.collection.test_list.testRemoveToZero(List, &list, a);
    try lib.collection.test_list.testIndexError(List, &list, a);
    try lib.collection.test_list.testGetFromLast(List, &list, a);
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
