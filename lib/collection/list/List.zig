const std = @import("std");
const lib = @import("../../root.zig");
const node_utils = lib.collection.list.node.linear;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn SingleLinearList(T: type) type {
    return struct {
        pub const Item = T;

        const List = @This();
        pub const Node = ListNode(T);

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: ?*Node,

        /// 新しい要素を持たないリストのインスタンスを生成し、それを返します。
        /// インスタンスを解放するときはクリーンアップのため、`List.deinit`を呼び出してください。
        pub fn init() List {
            return .{ .head = null };
        }

        /// 全てのノードを削除します。
        /// リストが持つ値の解放は行いません。
        pub fn deinit(self: *List, a: Allocator) void {
            node_utils.clear(a, self.head);
            self.* = undefined;
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            return node_utils.size(self.head);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            node_utils.clear(a, self.head);
            self.head = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) ?*Node {
            return node_utils.getNode(self.head, index);
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: List, index: usize) ?*T {
            return if (self.getNode(index)) |n| &n.value else null;
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *List, a: Allocator, index: usize, value: T) AllocIndexError!void {
            if (index == 0) {
            self.head = try Node.init(a, value, self.head);
            return ;
            }

            const node = self.getNode(index - 1) orelse return error.OutOfBounds;
            node.next = try Node.init(a, value, node.next);
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            if (index == 0) {
                const node = self.head orelse return error.OutOfBounds;

            self.head = node.next;
            node.deinit(a);
      return;
            }

            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            const node = prev.next orelse return error.OutOfBounds;

            prev.next = node.next;
            node.deinit(a);
        }

        pub const Iterator = struct {};

        pub fn iterator(self: List) Iterator {
            _ = self;
        }
        
        pub fn format(self: List, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            assert(self.isValidList());

            const type_name = "SingleLinearList(" ++ @typeName(T) ++ ")";
            try node_utils.format(w, type_name, self.head);
        }
    };
}

fn ListNode(T: type) type {
        return  struct {
            value: Item,
            next: ?*@This(),

            /// 値を持つノードのメモリを作成する。
            fn init(a: Allocator, value: T, next: ?*Node) Allocator.Error!*Node {
                const node = try a.create(Node);
                node.* = .{ .value = value, .next = next };
                return node;
            }

            /// 値を持つノードのメモリを作成する。
            /// 自分自身をnextに指定する。
            fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
                const node = try a.create(Node);
                node.* = .{ .value = value, .next = node };
                return node;
            }

            /// このノードを削除してメモリを解放する。
            fn deinit(node: *Node, a: Allocator) void {
                a.destroy(node);
            }

        pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("{}", .{node.value});
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
    try lib.collection.list.test_list.testList(List, &list, a);
    try lib.collection.list.test_list.testRemoveToZero(List, &list, a);
    try lib.collection.list.test_list.testIndexError(List, &list, a);
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
