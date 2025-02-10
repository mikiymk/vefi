const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;

pub fn SingleLinearList(T: type) type {
    return struct {
        const List = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: ?*Node = null,

            /// 値を持つノードのメモリを作成する。
            pub fn init(a: Allocator, value: T, next: ?*Node) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = next };
                return node;
            }

            /// このノードを削除してメモリを解放する。
            pub fn deinit(node: *Node, a: Allocator) void {
                const next = node.next;
                node.* = next.*;
                if (next) |n| a.destroy(n);
            }
        };

        head: ?*Node = null,

        /// 空のリストを作成する。
        pub fn init() List {
            return .{};
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            var node: ?*Node = self.head;

            while (node) |n| {
                const next = n.next;
                a.destroy(n);
                node = next;
            }
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            var node: ?*Node = self.head;
            var count: usize = 0;
            while (node) |n| {
                node = n.next;
                count += 1;
            }
            return count;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) ?*Node {
            var count = index;
            var node = self.head;
            while (node) |n| {
                if (count == 0) {
                    return n;
                }

                node = n.next;
                count -= 1;
            }

            return null;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?T {
            return if (self.getNode(index)) |n| n.value else null;
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) ?*Node {
            return self.head;
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: List) ?T {
            return if (self.getFirstNode()) |n| n.value else null;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) ?*Node {
            var prev: ?*Node = null;
            var node = self.head;

            while (node) |n| {
                const next = n.next;
                prev = n;
                node = next;
            }

            return prev;
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: List) ?T {
            return if (self.getLastNode()) |n| n.value else null;
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) void {
            const new_node = try Node.init(a, value, null);

            if (self.getNode(index)) |n| {
                n.next = new_node;
            } else {
                self.head = new_node;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const new_node = try Node.init(a, value, self.head);

            self.head = new_node;
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const new_node = try Node.init(a, value, null);

            if (self.getLastNode()) |n| {
                n.next = new_node;
            } else {
                self.head = new_node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) void {
            _ = .{ self, a, index };
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) void {
            _ = .{ self, a };
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) void {
            _ = .{ self, a };
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
    };
}

test "list" {
    const L = SingleLinearList(u8);
    const allocator = std.testing.allocator;
    const assert = lib.assert.expect;

    var list = L.init();
    defer list.deinit(allocator);

    // list == []
    try assert(@TypeOf(list) == SingleLinearList(u8));
    try assert(list.size() == 0);
    try assert(list.getFirst() == null);
    try assert(list.getLast() == null);

    try list.addFirst(allocator, 5);
    try list.addFirst(allocator, 6);

    // list == [6, 5]
    try assert(list.size() == 2);
    try assert(list.getFirst() == 6);
    try assert(list.getLast() == 5);
    try assert(list.get(1) == 5);

    try list.addLast(allocator, 7);
    try list.addLast(allocator, 8);

    // list == [6, 5, 7, 8]
    try assert(list.size() == 4);
    try assert(list.getFirst() == 6);
    try assert(list.getLast() == 8);
    try assert(list.get(2) == 7);

    list.removeFirst(allocator);

    // list == [5, 7, 8]
    try assert(list.size() == 3);
    try assert(list.getFirst() == 5);
    try assert(list.getLast() == 8);
    try assert(list.get(2) == 8);

    list.removeLast(allocator);

    // list == [5, 7]
    try assert(list.size() == 2);
    try assert(list.getFirst() == 5);
    try assert(list.getLast() == 7);
    try assert(list.get(1) == 7);
}
