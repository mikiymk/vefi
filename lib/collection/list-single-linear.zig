const std = @import("std");
const lib = @import("../root.zig");
const list_util = @import("list.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

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
                a.destroy(node);
            }

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                try writer.print("{}", .{node.value});
            }
        };

        pub const IndexError = error{OutOfBounds};

        head: ?*Node,

        /// 空のリストを作成する。
        pub fn init() List {
            return .{ .head = null };
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
            return list_util.size(self.head);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            list_util.clear(a, self.head);
            self.head = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) ?*Node {
            return list_util.getNode(self.head, index);
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) ?*Node {
            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) ?*Node {
            var prev: ?*Node = null;
            var node = self.head;

            while (node) |n| : (node = n.next) {
                prev = n;
            }

            return prev;
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
        pub fn add(self: *List, a: Allocator, index: usize, value: T) (Allocator.Error || IndexError)!void {
            if (index == 0) {
                return self.addFirst(a, value);
            }

            const node = self.getNode(index - 1) orelse return error.OutOfBounds;
            node.next = try Node.init(a, value, node.next);
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            self.head = try Node.init(a, value, self.head);
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const node = try Node.init(a, value, null);

            if (self.getLastNode()) |prev| {
                prev.next = node;
            } else {
                self.head = node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            if (index == 0) return self.removeFirst(a);

            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            const node = prev.next orelse return error.OutOfBounds;

            prev.next = node.next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) IndexError!void {
            const node = self.head orelse return error.OutOfBounds;

            self.head = node.next;
            node.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            var pprev: ?*Node = null;
            var prev: ?*Node = null;
            var node = self.head;

            while (node) |n| : (node = n.next) {
                pprev = prev;
                prev = n;
            }

            const p = prev orelse return error.OutOfBounds;
            p.deinit(a);

            if (pprev) |n| {
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
            const type_name = "SingleLinearList(" ++ @typeName(T) ++ ")";

            try list_util.format(w, type_name, self.head);
        }
    };
}

test SingleLinearList {
    const List = SingleLinearList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == SingleLinearList(u8));
    try lib.collection.testList(List, &list, a);
}

test "format" {
    const List = SingleLinearList(u8);
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

    try lib.assert.expectEqualString("SingleLinearList(u8){ 1, 2, 3, 4, 5 }", format);
}
