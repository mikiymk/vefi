const std = @import("std");
const lib = @import("../root.zig");

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
            fn init(a: Allocator, value: T, next: *Node) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = next };
                return node;
            }

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            fn initNextSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = node };
                return node;
            }

            fn deinit(node: *Node, a: Allocator) void {
                a.destroy(node);
            }

            /// ノードの値を返す。
            fn getValue(node: *const Node, sentinel: *const Node) ?T {
                return if (node != sentinel) node.value else null;
            }

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                try writer.print("{{{}}} -> next", .{node.value});
            }
        };

        head: *Node,
        sentinel: *Node,

        /// 空のリストを作成する。
        pub fn init(a: Allocator) Allocator.Error!List {
            const sentinel = try Node.initNextSelf(a, undefined);
            return .{ .head = sentinel, .sentinel = sentinel };
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
            var node = self.head;
            var count: usize = 0;
            while (node != self.sentinel) : (node = node.next) {
                count += 1;
            }
            return count;
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            var node = self.head;
            while (node != self.sentinel) {
                const next = node.next;
                node.deinit(a);
                node = next;
            }
            self.head = self.sentinel;
            self.head.next = self.sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) *Node {
            var node = self.head;
            var count = index;
            while (node != self.sentinel) : (node = node.next) {
                if (count == 0) {
                    return node;
                }
                count -= 1;
            }
            return self.sentinel;
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) *Node {
            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) *Node {
            var prev = self.sentinel;
            var node = self.head;
            while (node != self.sentinel) : (node = node.next) {
                prev = node;
            }
            return prev;
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
        pub fn add(self: *List, a: Allocator, index: usize, value: T) Allocator.Error!void {
            if (index == 0) {
                try self.addFirst(a, value);
            } else {
                const prev = self.getNode(index - 1);
                const next = prev.next;
                prev.next = try Node.init(a, value, next);
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            self.head = try Node.init(a, value, self.head);
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const new_node = try Node.init(a, value, self.sentinel);

            const last = self.getLastNode();
            last.next = new_node;
            if (last == self.sentinel) {
                self.head = new_node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) void {
            if (index == 0) {
                self.removeFirst(a);
                return;
            }

            const prev = self.getNode(index - 1);
            const node = prev.next;
            prev.next = node.next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) void {
            const head = self.head;
            const next = head.next;
            self.sentinel.next = next;
            self.head = next;
            head.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) void {
            var prev_prev = self.sentinel;
            var prev = self.sentinel;
            var node = self.head;
            while (node != self.sentinel) : (node = node.next) {
                prev_prev = prev;
                prev = node;
            }

            if (prev_prev == self.sentinel) {
                self.head = self.sentinel;
            }
            prev_prev.next = self.sentinel;
            prev.deinit(a);
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
            while (node != self.sentinel) : (node = node.next) {
                try writer.print(" {d}: {}\n", .{ index, node });
                index += 1;
            }
        }
    };
}

test "list" {
    const List = SingleCircularSentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = try List.init(a);
    defer list.deinit(a);

    try expect(@TypeOf(list) == SingleCircularSentinelList(u8));
    try lib.collection.testList(List, &list, a);
}
