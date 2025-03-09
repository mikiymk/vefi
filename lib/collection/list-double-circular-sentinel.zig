const std = @import("std");
const lib = @import("../root.zig");
const generic_list = lib.collection.generic_list_sentinel;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn DoubleCircularSentinelList(T: type) type {
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

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            pub fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{
                    .value = value,
                    .next = node,
                    .prev = node,
                };
                return node;
            }

            pub fn deinit(node: *Node, a: Allocator) void {
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
        tail: *Node,
        sentinel: *Node,

        /// 空のリストを作成する。
        pub fn init(a: Allocator) Allocator.Error!List {
            const sentinel = try Node.initSelf(a, undefined);
            return .{
                .head = sentinel,
                .tail = sentinel,
                .sentinel = sentinel,
            };
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
                if (prev != node.prev) return false;
                prev = node;
            }

            if (prev != self.tail) return false;
            if (self.sentinel.next != self.head) return false;
            if (self.sentinel.prev != self.tail) return false;
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
            self.sentinel.next = self.sentinel;
            self.sentinel.prev = self.sentinel;
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

        fn addNode(a: Allocator, value: T, next: *Node, prev: *Node) Allocator.Error!*Node {
            const node = try Node.init(a, value, next, prev);
            prev.next = node;
            next.prev = node;

            return node;
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
            const node = try addNode(a, value, next, prev);

            if (next == self.sentinel) {
                self.tail = node;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const next = self.head;
            const prev = self.sentinel;
            const node = try addNode(a, value, next, prev);

            self.head = node;
            if (next == self.sentinel) {
                self.tail = node;
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const prev = self.tail;
            const next = self.sentinel;
            const node = try addNode(a, value, next, prev);

            if (prev == self.sentinel) {
                self.head = node;
            }
            self.tail = node;
        }

        fn removeNode(a: Allocator, node: *Node) void {
            const next = node.next;
            const prev = node.prev;

            prev.next = next;
            next.prev = prev;
            node.deinit(a);
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.getNode(index);
            if (node == self.sentinel) return error.OutOfBounds;
            const next = node.next;
            const prev = node.prev;

            removeNode(a, node);

            if (self.head == node) {
                self.head = next;
            }
            if (self.tail == node) {
                self.tail = prev;
            }
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.getFirstNode();
            if (node == self.sentinel) return error.OutOfBounds;
            const next = node.next;
            const prev = node.prev;

            removeNode(a, node);

            self.head = next;
            if (self.tail == node) {
                self.tail = prev;
            }
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.getLastNode();
            if (node == self.sentinel) return error.OutOfBounds;
            const next = node.next;
            const prev = node.prev;

            removeNode(a, node);

            if (self.head == node) {
                self.head = next;
            }
            self.tail = prev;
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
            const type_name = "DoubleCircularSentinelList(" ++ @typeName(T) ++ ")";
            try generic_list.format(w, type_name, self.head, self.sentinel);
        }
    };
}

test DoubleCircularSentinelList {
    const List = DoubleCircularSentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = try List.init(a);
    defer list.deinit(a);

    try expect(@TypeOf(list) == DoubleCircularSentinelList(u8));
    try lib.collection.testList(List, &list, a);
}

test "format" {
    const List = DoubleCircularSentinelList(u8);
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

    try lib.assert.expectEqualString("DoubleCircularSentinelList(u8){ 1, 2, 3, 4, 5 }", format);
}
