const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn SingleCircularList(T: type) type {
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

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                try writer.print("{{{}}} -> next", .{node.value});
            }
        };

        tail: ?*Node = null,

        /// 空のリストを作成する。
        pub fn init() List {
            return .{};
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            const tail = self.tail orelse return;

            var node = tail.next;
            while (true) {
                const next = node.next;

                node.deinit(a);

                if (node == tail) break;

                node = next;
            }
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            const tail = self.tail orelse return 0;

            var node = tail.next;
            var count: usize = 0;
            while (true) : (node = node.next) {
                count += 1;

                if (node == tail) return count;
            }
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            const tail = self.tail orelse return;

            var node = tail.next;
            while (true) {
                const next = node.next;

                node.deinit(a);

                if (node == tail) break;

                node = next;
            }
            self.tail = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) ?*Node {
            const tail = self.tail orelse return null;
            const head = tail.next;

            var node = head;
            var count = index;
            while (true) : (node = node.next) {
                if (count == 0) {
                    return node;
                }
                count -= 1;

                if (node == tail) return null;
            }
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) ?*Node {
            const tail = self.tail orelse return null;
            return tail.next;
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
            } else if (self.getNode(index - 1)) |n| {
                const next = n.next;
                n.next = try Node.init(a, value, next);
            } else {
                // indexが範囲外の場合
                unreachable;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            if (self.tail) |tail| {
                const new_node = try Node.init(a, value, tail.next);
                tail.next = new_node;
            } else {
                self.tail = try Node.initNextSelf(a, value);
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            if (self.tail) |tail| {
                const new_node = try Node.init(a, value, tail.next);
                tail.next = new_node;
                self.tail = new_node;
            } else {
                self.tail = try Node.initNextSelf(a, value);
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) void {
            if (index == 0) {
                self.removeFirst(a);
                return;
            }

            const prev = self.getNode(index - 1).?;
            const node = prev.next;
            prev.next = node.next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) void {
            assert(self.tail != null);

            const tail = self.tail.?;
            const head = tail.next;
            tail.next = head.next;
            if (tail == head) {
                self.tail = null;
            }
            head.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) void {
            assert(self.tail != null);

            const tail = self.tail.?;
            const head = tail.next;

            var prev: *Node = tail;
            var node = head;
            while (true) : (node = node.next) {
                if (node == tail) {
                    break;
                }
                prev = node;
            }

            prev.next = head;
            if (node != prev) {
                self.tail = prev;
            } else {
                self.tail = null;
            }
            node.deinit(a);
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

            const tail = self.tail orelse {
                try writer.print("\n", .{});
                return;
            };

            var node = tail.next;
            var index: usize = 0;
            while (node != tail) {
                try writer.print(" {d}: {}\n", .{ index, node });
                node = node.next;
                index += 1;
            }
            try writer.print(" {d}: {}\n", .{ index, node });
        }
    };
}

test "list" {
    const List = SingleCircularList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == SingleCircularList(u8));

    // list == .{}
    try expect(list.size() == 0);
    try expect(list.getFirst() == null);
    try expect(list.getLast() == null);

    try list.addFirst(a, 4);
    try list.addFirst(a, 3);

    // list == .{3, 4}
    try expect(list.size() == 2);
    try expect(list.getFirst() == 3);
    try expect(list.getLast() == 4);
    try expect(list.get(0) == 3);
    try expect(list.get(1) == 4);

    try list.addLast(a, 7);
    try list.addLast(a, 8);

    // list == .{3, 4, 7, 8}
    try expect(list.size() == 4);
    try expect(list.get(0) == 3);
    try expect(list.get(1) == 4);
    try expect(list.get(2) == 7);
    try expect(list.get(3) == 8);

    try list.add(a, 2, 5);
    try list.add(a, 3, 6);

    // list == .{3, 4, 5, 6, 7, 8}
    try expect(list.size() == 6);
    try expect(list.getFirst() == 3);
    try expect(list.getLast() == 8);
    try expect(list.get(0) == 3);
    try expect(list.get(1) == 4);
    try expect(list.get(2) == 5);
    try expect(list.get(3) == 6);
    try expect(list.get(4) == 7);
    try expect(list.get(5) == 8);

    list.removeFirst(a);

    // list == .{4, 5, 6, 7, 8}
    try expect(list.size() == 5);
    try expect(list.get(0) == 4);
    try expect(list.get(1) == 5);
    try expect(list.get(2) == 6);
    try expect(list.get(3) == 7);
    try expect(list.get(4) == 8);

    list.removeLast(a);

    // list == .{4, 5, 6, 7}
    try expect(list.size() == 4);
    try expect(list.get(0) == 4);
    try expect(list.get(1) == 5);
    try expect(list.get(2) == 6);
    try expect(list.get(3) == 7);

    list.remove(a, 1);

    // list == .{4, 6, 7}
    try expect(list.size() == 3);
    try expect(list.get(0) == 4);
    try expect(list.get(1) == 6);
    try expect(list.get(2) == 7);

    list.clear(a);

    // list == .{}
    try expect(list.size() == 0);
    try expect(list.getFirst() == null);
    try expect(list.getLast() == null);

    try list.addFirst(a, 1);
    list.removeFirst(a);
    try expect(list.size() == 0);

    try list.addLast(a, 1);
    list.removeLast(a);
    try expect(list.size() == 0);

    try list.add(a, 0, 1);
    list.remove(a, 0);
    try expect(list.size() == 0);
}
