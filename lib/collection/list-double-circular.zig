const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn DoubleCircularList(T: type) type {
    return struct {
        const List = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = struct {
            value: Item,
            next: *Node,
            prev: *Node,

            /// 値を持つノードのメモリを作成する。
            fn init(a: Allocator, value: T, next: *Node, prev: *Node) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = next, .prev = prev };
                return node;
            }

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = node, .prev = node };
                return node;
            }

            fn deinit(node: *Node, a: Allocator) void {
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
        pub fn init() List {
            return .{
                .head = null,
                .tail = null,
            };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            const head = self.head orelse return;
            var node = head;

            while (true) {
                const next = node.next;
                node.deinit(a);
                node = next;
                if (node == head) break; // do-whileになる
            }
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: List) bool {
            const head = self.head orelse return true;
            var prev = head;
            var node = prev.next;

            while (node != self.head) : (node = node.next) {
                if (node.prev != prev) @panic("!");
                prev = node;
            }

            if (self.tail != prev) @panic("!");
            if (prev.next != head) @panic("!");
            if (prev != head.prev) @panic("!");
            return true;
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            assert(self.isValidList());

            const head = self.head orelse return 0;
            var node = head;
            var count: usize = 0;
            while (true) : (node = node.next) {
                count += 1;
                if (node.next == head) break;
            }
            return count;
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const head = self.head orelse return;
            var node = head;

            while (true) {
                const next = node.next;
                node.deinit(a);
                node = next;
                if (node == head) break; // do-whileになる
            }
            self.head = null;
            self.tail = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) ?*Node {
            assert(self.isValidList());

            const head = self.head orelse return null;
            var node = head;
            var count = index;

            while (true) : (node = node.next) {
                if (count == 0) return node;
                count -= 1;
                if (node.next == head) return null;
            }
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) ?*Node {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) ?*Node {
            assert(self.isValidList());

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

        fn addNode(a: Allocator, value: T, next: *Node, prev: *Node) Allocator.Error!*Node {
            const node = try Node.init(a, value, next, prev);
            prev.next = node;
            next.prev = node;
            return node;
        }

        fn addNodeSelf(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const node = try Node.initSelf(a, value);
            self.head = node;
            self.tail = node;
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) AllocIndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.addFirst(a, value);
            }

            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            _ = try addNode(a, value, prev.next, prev);
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (self.getFirstNode()) |next| {
                const node = try addNode(a, value, next, next.prev);
                self.head = node;
            } else {
                try self.addNodeSelf(a, value);
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (self.getLastNode()) |prev| {
                const node = try addNode(a, value, prev.next, prev);
                self.tail = node;
            } else {
                try self.addNodeSelf(a, value);
            }
        }

        fn removeNode(a: Allocator, node: *Node, next: *Node, prev: *Node) void {
            prev.next = next;
            next.prev = prev;
            node.deinit(a);
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.removeFirst(a);
            }

            const node = self.getNode(index) orelse return error.OutOfBounds;
            removeNode(a, node, node.next, node.prev);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.getFirstNode() orelse return error.OutOfBounds;
            const prev = node.prev;
            const next = node.next;

            self.head = next;
            if (prev == next) {
                self.tail = next;
            }

            if (node == next) {
                self.head = null;
                self.tail = null;
            }

            removeNode(a, node, next, prev);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.getLastNode() orelse return error.OutOfBounds;
            const prev = node.prev;
            const next = node.next;

            self.tail = prev;
            if (prev == next) {
                self.head = prev;
            }

            if (node == next) {
                self.head = null;
                self.tail = null;
            }

            removeNode(a, node, next, prev);
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
            const type_name = "DoubleCircularList(" ++ @typeName(T) ++ ")";
            const writer = lib.io.writer(w);

            try writer.print("{s}{{", .{type_name});
            if (self.head) |head| {
                var node = head;
                var first = true;
                while (true) : (node = node.next) {
                    if (first) {
                        try writer.print(" ", .{});
                        first = false;
                    } else {
                        try writer.print(", ", .{});
                    }

                    try writer.print("{}", .{node});

                    if (node.next == head) break;
                }
            }
            try writer.print(" }}", .{});
        }
    };
}

test DoubleCircularList {
    const List = DoubleCircularList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == DoubleCircularList(u8));
    try lib.collection.testList(List, &list, a);
}

test "format" {
    const List = DoubleCircularList(u8);
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

    try lib.assert.expectEqualString("DoubleCircularList(u8){ 1, 2, 3, 4, 5 }", format);
}
