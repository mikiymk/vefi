const std = @import("std");
const lib = @import("../../root.zig");
const generic_list = lib.collection.list.generic_list_sentinel;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn SingleCircularSentinelList(T: type) type {
    return struct {
        const List = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: *Node,

            /// 値を持つノードのメモリを作成する。
            pub fn init(a: Allocator, value: T, next: *Node) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = next };
                return node;
            }

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            pub fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = node };
                return node;
            }

            pub fn deinit(node: *const Node, a: Allocator) void {
                a.destroy(node);
            }

            /// ノードの値を返す。
            pub fn getValue(node: *const Node, sentinel: *const Node) ?T {
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
        pub fn init(a: Allocator) Allocator.Error!List {
            const sentinel = try a.create(Node);
            sentinel.next = sentinel;

            return .{ .head = sentinel, .sentinel = sentinel };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            generic_list.clear(a, self.head, self.sentinel);
            self.sentinel.deinit(a);
            self.* = undefined;
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: List) bool {
            if (self.sentinel.next != self.head) return false;
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
            self.sentinel.next = self.sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) *Node {
            assert(self.isValidList());

            return generic_list.getNode(self.head, self.sentinel, index);
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) *Node {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) *Node {
            assert(self.isValidList());

            return generic_list.getLastNode(self.head, self.sentinel);
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
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.addFirst(a, value);
            }

            const prev = self.getNode(index - 1);
            if (prev == self.sentinel) return error.OutOfBounds;
            const next = prev.next;

            prev.next = try Node.init(a, value, next);
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = try Node.init(a, value, self.head);

            self.sentinel.next = node;
            self.head = node;
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = try Node.init(a, value, self.sentinel);
            const prev = self.getLastNode();

            prev.next = node;

            if (prev == self.sentinel) {
                self.head = node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) return self.removeFirst(a);

            const prev = self.getNode(index - 1);
            if (prev == self.sentinel) return error.OutOfBounds;
            const node = prev.next;
            if (node == self.sentinel) return error.OutOfBounds;

            prev.next = node.next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.head;
            if (node == self.sentinel) return error.OutOfBounds;
            const next = node.next;

            self.sentinel.next = next;
            node.deinit(a);

            self.head = next;
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            var prev_prev = self.sentinel;
            var prev = self.sentinel;
            var node = self.head;
            while (node != self.sentinel) : (node = node.next) {
                prev_prev = prev;
                prev = node;
            }

            if (prev == self.sentinel) return error.OutOfBounds;

            prev_prev.next = self.sentinel;
            prev.deinit(a);

            if (prev_prev == self.sentinel) {
                self.head = self.sentinel;
                self.sentinel.next = self.sentinel;
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
            assert(self.isValidList());

            const type_name = "SingleCircularSentinelList(" ++ @typeName(T) ++ ")";
            try generic_list.format(w, type_name, self.head, self.sentinel);
        }
    };
}

test SingleCircularSentinelList {
    const List = SingleCircularSentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = try List.init(a);
    defer list.deinit(a);

    try expect(@TypeOf(list) == SingleCircularSentinelList(u8));
    try lib.collection.list.test_list.testList(List, &list, a);
    try lib.collection.list.test_list.testRemoveToZero(List, &list, a);
    try lib.collection.list.test_list.testIndexError(List, &list, a);
}

test "format" {
    const List = SingleCircularSentinelList(u8);
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

    try lib.assert.expectEqualString("SingleCircularSentinelList(u8){ 1, 2, 3, 4, 5 }", format);
}
