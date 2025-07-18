const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn CircularList(T: type) type {
    return struct {
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
            fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node: *Node = try a.create(Node);
                node.* = .{ .value = value, .next = node };
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

        /// 空のリストを作成する。
        pub fn init() @This() {
            return .{ .head = null };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *@This(), a: Allocator) void {
            const head = self.head orelse return;
            var node = head;

            while (true) {
                const next = node.next;
                node.deinit(a);
                node = next;
                if (node == head) break; // do-whileになる
            }
            self.* = undefined;
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: @This()) bool {
            const head = self.head orelse return true;
            var prev = head;
            var node = prev.next;

            while (node != self.head) : (node = node.next) {
                prev = node;
            }

            if (prev.next != head) return false;
            return true;
        }

        /// リストの要素数を数える
        pub fn size(self: @This()) usize {
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
        pub fn clear(self: *@This(), a: Allocator) void {
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
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: @This(), index: usize) ?*Node {
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
        fn getFirstNode(self: @This()) ?*Node {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: @This()) ?*Node {
            assert(self.isValidList());

            var prev = self.head orelse return null;
            var node = prev.next;

            while (node != self.head) : (node = node.next) {
                prev = node;
            }

            return prev;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: @This(), index: usize) ?T {
            return if (self.getNode(index)) |n| n.value else null;
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
            prev.next = try Node.init(a, value, prev.next);
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *@This(), a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (self.getLastNode()) |prev| {
                const node = try Node.init(a, value, prev.next);
                prev.next = node;

                self.head = node;
            } else {
                self.head = try Node.initSelf(a, value);
            }
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *@This(), a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (self.getLastNode()) |prev| {
                prev.next = try Node.init(a, value, prev.next);
            } else {
                self.head = try Node.initSelf(a, value);
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *@This(), a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.removeFirst(a);
            }

            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            const node = prev.next;
            const next = node.next;

            prev.next = next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *@This(), a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const prev = self.getLastNode() orelse return error.OutOfBounds;
            const node = self.head.?;
            const next = node.next;

            prev.next = next;
            node.deinit(a);

            if (node == next) {
                self.head = null;
            } else {
                self.head = next;
            }
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *@This(), a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const head = self.head orelse return error.OutOfBounds;

            var prev_prev = head;
            var prev = head;
            var node = head.next;
            while (true) : (node = node.next) {
                if (node == head) break;
                prev_prev = prev;
                prev = node;
            }

            //                  1     2         3~
            // prev_prev ->  head  head  prev_last
            // prev      ->  head  last       last
            // node      ->  head  head       head

            prev_prev.next = node;
            prev.deinit(a);

            if (node == prev) {
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

            const type_name = "SingleCircularList(" ++ @typeName(T) ++ ")";
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

test CircularList {
    const List = CircularList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == CircularList(u8));
    try lib.collection.list.test_list.testList(List, &list, a);
    try lib.collection.list.test_list.testRemoveToZero(List, &list, a);
    try lib.collection.list.test_list.testIndexError(List, &list, a);
}

test "format" {
    const List = CircularList(u8);
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

    try lib.assert.expectEqualString("SingleCircularList(u8){ 1, 2, 3, 4, 5 }", format);
}
