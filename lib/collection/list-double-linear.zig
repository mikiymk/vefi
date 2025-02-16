const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn DoubleLinearList(T: type) type {
    return struct {
        const List = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: ?*Node = null,
            prev: ?*Node = null,

            /// 値を持つノードのメモリを作成する。
            pub fn init(a: Allocator, value: T, next: ?*Node, prev: ?*Node) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = next, .prev = prev };
                return node;
            }

            /// このノードを削除してメモリを解放する。
            pub fn deinit(node: *Node, a: Allocator) void {
                a.destroy(node);
            }

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const next_str = "next";
                const prev_str = "prev";
                const null_str = "null";

                const writer = lib.io.writer(w);
                const next = if (node.next) |_| next_str else null_str;
                const prev = if (node.prev) |_| prev_str else null_str;

                try writer.print("{{{s} <- {} -> {s}}}", .{ prev, node.value, next });
            }
        };

        head: ?*Node = null,
        tail: ?*Node = null,

        /// 空のリストを作成する。
        pub fn init() List {
            return .{};
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            var node: ?*Node = self.head;

            while (node) |n| {
                const next = n.next;
                n.deinit(a);
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

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            var node: ?*Node = self.head;

            while (node) |n| {
                const next = n.next;
                n.deinit(a);
                node = next;
            }
            self.head = null;
            self.tail = null;
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

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) ?*Node {
            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) ?*Node {
            return self.tail;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?T {
            return if (self.getNode(index)) |n| n.value else null;
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: List) ?T {
            return if (self.getFirstNode()) |n| n.value else null;
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: List) ?T {
            return if (self.getLastNode()) |n| n.value else null;
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) Allocator.Error!void {
            if (index == 0) {
                try self.addFirst(a, value);
                return;
            }

            const prev = self.getNode(index - 1).?;
            const next = prev.next;
            const new_node = try Node.init(a, value, next, prev);
            prev.next = new_node;
            if (next) |n| {
                n.prev = new_node;
            } else {
                self.tail = new_node;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const next = self.head;
            const new_node = try Node.init(a, value, next, null);

            self.head = new_node;
            if (next) |n| {
                n.prev = new_node;
            } else {
                self.tail = new_node;
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const prev = self.tail;
            const new_node = try Node.init(a, value, null, prev);

            self.tail = new_node;
            if (prev) |n| {
                n.next = new_node;
            } else {
                self.head = new_node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) void {
            if (index == 0) {
                self.removeFirst(a);
                return;
            }

            const node = self.getNode(index).?;
            const prev = node.prev;
            const next = node.next;
            node.deinit(a);

            if (prev) |n| {
                n.next = next;
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
        pub fn removeFirst(self: *List, a: Allocator) void {
            const head = self.head.?;
            const next = head.next;
            head.deinit(a);
            self.head = next;
            if (next) |n| {
                n.prev = null;
            } else {
                self.tail = null;
            }
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) void {
            const tail = self.tail.?;
            const prev = tail.prev;
            tail.deinit(a);
            self.tail = prev;
            if (prev) |n| {
                n.next = null;
            } else {
                self.head = null;
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
            while (node) |n| {
                try writer.print(" {d}: {}\n", .{ index, n });
                node = n.next;
                index += 1;
            }
        }
    };
}

test "list" {
    const List = DoubleLinearList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == DoubleLinearList(u8));
    try lib.collection.testList(List, &list, a);
}
