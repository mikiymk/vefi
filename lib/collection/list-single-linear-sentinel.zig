const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn SingleLinearSentinelList(T: type) type {
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

            /// このノードを削除してメモリを解放する。
            pub fn deinit(node: *Node, a: Allocator) void {
                if (node != ref_sentinel) {
                    a.destroy(node);
                }
            }

            /// ノードの値を返す。
            fn getValue(node: *const Node) ?T {
                return if (node != ref_sentinel) node.value else null;
            }

            pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
                const writer = lib.io.writer(w);
                if (node == ref_sentinel) {
                    try writer.print("sentinel", .{});
                } else {
                    try writer.print("{{{}}} -> next", .{node.value});
                }
            }
        };

        var sentinel: Node = undefined;
        pub const ref_sentinel = &sentinel;

        head: *Node,

        /// 空のリストを作成する。
        pub fn init() List {
            return .{ .head = ref_sentinel };
        }

        /// リストに含まれる全てのノードを削除する。
        pub fn deinit(self: *List, a: Allocator) void {
            var node = self.head;

            while (node != ref_sentinel) {
                const next = node.next;
                a.destroy(node);
                node = next;
            }
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            var node = self.head;
            var count: usize = 0;
            while (node != ref_sentinel) : (node = node.next) {
                count += 1;
            }
            return count;
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            var node = self.head;

            while (node != ref_sentinel) {
                const next = node.next;
                a.destroy(node);
                node = next;
            }
            self.head = ref_sentinel;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) *Node {
            var count = index;
            var node = self.head;
            while (node != ref_sentinel and count != 0) : (node = node.next) {
                count -= 1;
            }
            return node;
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) *Node {
            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) *Node {
            var prev = ref_sentinel;
            var node = self.head;

            while (node != ref_sentinel) : (node = node.next) {
                prev = node;
            }

            return prev;
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?T {
            return self.getNode(index).getValue();
        }

        /// リストの先頭の要素を返す。
        pub fn getFirst(self: List) ?T {
            return self.getFirstNode().getValue();
        }

        /// リストの末尾の要素を返す。
        pub fn getLast(self: List) ?T {
            return self.getLastNode().getValue();
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) Allocator.Error!void {
            if (index == 0) {
                self.head = try Node.init(a, value, self.head);
                return;
            }

            const node = self.getNode(index - 1);
            if (node != ref_sentinel) {
                node.next = try Node.init(a, value, node.next);
            } else {
                // indexが範囲外の場合
                unreachable;
            }
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            self.head = try Node.init(a, value, self.head);
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            const new_node = try Node.init(a, value, ref_sentinel);
            const last_node = self.getLastNode();

            if (last_node != ref_sentinel) {
                last_node.next = new_node;
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

            const node = self.getNode(index - 1);
            if (node != ref_sentinel) {
                const target = node.next;
                node.next = target.next;
                target.deinit(a);
            } else {
                // indexが範囲外の場合
                unreachable;
            }
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) void {
            const target = self.head;
            self.head = target.next;
            target.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) void {
            var prev_prev: *Node = ref_sentinel;
            var prev: *Node = ref_sentinel;
            var node: *Node = self.head;

            while (node != ref_sentinel) : (node = node.next) {
                prev_prev = prev;
                prev = node;
            }

            prev.deinit(a);
            if (prev_prev != ref_sentinel) {
                prev_prev.next = ref_sentinel;
            } else {
                self.head = ref_sentinel;
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
            while (node != ref_sentinel) : (node = node.next) {
                try writer.print(" {d}: {}\n", .{ index, node });
                index += 1;
            }
        }
    };
}

test "list" {
    const List = SingleLinearSentinelList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = List.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == SingleLinearSentinelList(u8));

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
