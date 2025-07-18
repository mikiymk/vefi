const std = @import("std");
const lib = @import("../../root.zig");
const generic_list = lib.collection.list.generic_list;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn DoublyList(T: type) type {
    return struct {
        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: ?*Node,
            prev: ?*Node,

            /// 値を持つノードのメモリを作成する。
            pub fn init(a: Allocator, value: T, next: ?*Node, prev: ?*Node) Allocator.Error!*Node {
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

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                try writer.print("{}", .{node.value});
            }
        };

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: ?*Node,
        tail: ?*Node,

        /// 空のリストを作成する。
        pub fn init() @This() {
            return .{ .head = null, .tail = null };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *@This(), a: Allocator) void {
            generic_list.clear(a, self.head);
            self.* = undefined;
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: @This()) bool {
            var prev: ?*Node = null;
            var node = self.head;
            while (node) |n| : (node = n.next) {
                if (n.prev != prev) return false;
                prev = node;
            }

            return true;
        }

        /// リストの要素数を数える
        pub fn size(self: @This()) usize {
            assert(self.isValidList());

            return generic_list.size(self.head);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *@This(), a: Allocator) void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            generic_list.clear(a, self.head);
            self.head = null;
            self.tail = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: @This(), index: usize) ?*Node {
            assert(self.isValidList());

            return generic_list.getNode(self.head, index);
        }

        /// リストの最後から指定した位置のノードを返す。
        fn getNodeFromLast(self: @This(), index: usize) ?*Node {
            assert(self.isValidList());

            var node = self.tail;
            var count = index;

            return while (node) |n| : (node = n.prev) {
                if (count == 0) break n;
                count -= 1;
            } else null;
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: @This()) ?*Node {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: @This()) ?*Node {
            assert(self.isValidList());

            return self.tail;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: @This(), index: usize) ?T {
            return if (self.getNode(index)) |n| n.value else null;
        }

        /// リストの最後から指定した位置の要素を返す。
        pub fn getFromLast(self: @This(), index: usize) ?T {
            return if (self.getNodeFromLast(index)) |n| n.value else null;
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: @This()) ?T {
            return if (self.getFirstNode()) |n| n.value else null;
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: @This()) ?T {
            return if (self.getLastNode()) |n| n.value else null;
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *@This(), a: Allocator, index: usize, value: T) AllocIndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.addFirst(a, value);
            }

            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            const next = prev.next;

            const node = try Node.init(a, value, next, prev);
            prev.next = node;
            if (next) |n| {
                n.prev = node;
            } else {
                self.tail = node;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *@This(), a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const next = self.head;
            const node = try Node.init(a, value, next, null);

            self.head = node;
            if (next) |n| {
                n.prev = node;
            } else {
                self.tail = node;
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *@This(), a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const prev = self.tail;
            const node = try Node.init(a, value, null, prev);

            self.tail = node;
            if (prev) |p| {
                p.next = node;
            } else {
                self.head = node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *@This(), a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) return self.removeFirst(a);

            const node = self.getNode(index) orelse return error.OutOfBounds;
            const prev = node.prev;
            const next = node.next;

            node.deinit(a);
            if (prev) |p| {
                p.next = next;
            } else {
                self.head = next;
            }
            if (next) |n| {
                n.prev = prev;
            } else {
                self.tail = prev;
            }
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *@This(), a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.head orelse return error.OutOfBounds;
            const next = node.next;

            node.deinit(a);
            self.head = next;
            if (next) |n| {
                n.prev = null;
            } else {
                self.tail = null;
            }
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *@This(), a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.tail orelse return error.OutOfBounds;
            const prev = node.prev;

            node.deinit(a);
            self.tail = prev;
            if (prev) |n| {
                n.next = null;
            } else {
                self.head = null;
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

            const type_name = "DoubleLinearList(" ++ @typeName(T) ++ ")";
            try generic_list.format(w, type_name, self.head);
        }
    };
}

test DoublyList {
    const List = DoublyList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == DoublyList(u8));
    try lib.collection.list.test_list.testList(List, &list, a);
    try lib.collection.list.test_list.testRemoveToZero(List, &list, a);
    try lib.collection.list.test_list.testIndexError(List, &list, a);
    try lib.collection.list.test_list.testGetFromLast(List, &list, a);
}

test "format" {
    const List = DoublyList(u8);
    const a = std.testing.allocator;

    var list = List.init();
    defer list.deinit(a);

    try list.addLast(a, 1);
    try list.addLast(a, 2);
    try list.addLast(a, 3);
    try list.addLast(a, 4);
    try list.addLast(a, 5);

    const format = try std.fmt.allocPrint(a, "{}", .{list});
    defer a.free(format);

    try lib.assert.expectEqualString("DoubleLinearList(u8){ 1, 2, 3, 4, 5 }", format);
}
