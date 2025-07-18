const std = @import("std");
const lib = @import("../../root.zig");
const generic_list = lib.collection.list.generic_list_sentinel;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn SentinelList(T: type) type {
    return struct {
        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: *Node,

            /// 値を持つノードのメモリを作成する。
            pub fn init(a: Allocator, value: T, next: *Node) Allocator.Error!*Node {
                const node = try a.create(Node);
                node.* = .{ .value = value, .next = next };
                return node;
            }

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node = try a.create(Node);
                node.* = .{ .value = value, .next = node };
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

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                try writer.print("{}", .{node.value});
            }
        };

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: *Node,
        sentinel: *Node,

        /// 空のリストを作成する。
        pub fn init(a: Allocator) Allocator.Error!@This() {
            var sentinel = try a.create(Node);
            sentinel.next = sentinel;

            return .{ .head = sentinel, .sentinel = sentinel };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *@This(), a: Allocator) void {
            generic_list.clear(a, self.head, self.sentinel);
            self.sentinel.deinit(a);
            self.* = undefined;
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: @This()) bool {
            if (self.sentinel.next != self.sentinel) return false;
            return true;
        }

        /// リストの要素数を数える
        pub fn size(self: @This()) usize {
            assert(self.isValidList());

            return generic_list.size(self.head, self.sentinel);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *@This(), a: Allocator) void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            generic_list.clear(a, self.head, self.sentinel);
            self.head = self.sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: @This(), index: usize) *Node {
            assert(self.isValidList());

            return generic_list.getNode(self.head, self.sentinel, index);
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: @This()) *Node {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: @This()) *Node {
            assert(self.isValidList());

            return generic_list.getLastNode(self.head, self.sentinel);
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: @This(), index: usize) ?T {
            return self.getNode(index).getValue(self.sentinel);
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: @This()) ?T {
            return self.getFirstNode().getValue(self.sentinel);
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: @This()) ?T {
            return self.getLastNode().getValue(self.sentinel);
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *@This(), a: Allocator, index: usize, value: T) AllocIndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.addFirst(a, value);
            }

            const node = self.getNode(index - 1);
            if (node == self.sentinel) return error.OutOfBounds;

            node.next = try Node.init(a, value, node.next);
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *@This(), a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            self.head = try Node.init(a, value, self.head);
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *@This(), a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = try Node.init(a, value, self.sentinel);
            const prev = self.getLastNode();

            if (prev != self.sentinel) {
                prev.next = node;
            } else {
                self.head = node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *@This(), a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.removeFirst(a);
            }

            const prev = self.getNode(index - 1);
            const node = prev.next;
            if (node == self.sentinel) return error.OutOfBounds;

            prev.next = node.next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *@This(), a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.head;
            if (node == self.sentinel) return error.OutOfBounds;

            self.head = node.next;
            node.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *@This(), a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            var prev_prev = self.sentinel;
            var prev = self.sentinel;
            var node = self.head;

            while (node != self.sentinel) : ({
                prev_prev = prev;
                prev = node;
                node = node.next;
            }) {}

            if (prev == self.sentinel) return error.OutOfBounds;
            prev.deinit(a);

            if (prev_prev != self.sentinel) {
                prev_prev.next = self.sentinel;
            } else {
                self.head = self.sentinel;
            }
        }

        /// リストを複製する。
        pub fn copy(self: @This(), a: Allocator) @This() {
            _ = .{ self, a };
        }

        pub const Iterator = struct {};

        pub fn iterator(self: @This()) Iterator {
            _ = self;
        }

        pub fn equal(left: @This(), right: @This()) bool {
            _ = left;
            _ = right;
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            assert(self.isValidList());

            const type_name = "SingleLinearSentinelList(" ++ @typeName(T) ++ ")";
            try generic_list.format(w, type_name, self.head, self.sentinel);
        }
    };
}

test SentinelList {
    const List = SentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = try List.init(a);
    defer list.deinit(a);

    try expect(@TypeOf(list) == SentinelList(u8));
    try lib.collection.list.test_list.testList(List, &list, a);
    try lib.collection.list.test_list.testRemoveToZero(List, &list, a);
    try lib.collection.list.test_list.testIndexError(List, &list, a);
}

test "format" {
    const List = SentinelList(u8);
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

    try lib.assert.expectEqualString("SingleLinearSentinelList(u8){ 1, 2, 3, 4, 5 }", format);
}
