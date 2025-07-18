const std = @import("std");
const lib = @import("../../root.zig");
const node_utils = lib.collection.list.node.linear;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn SinglyList(T: type) type {
    return struct {
        pub const Item = T;

        pub const Node = ListNode(T);

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: ?*Node,

        /// 新しい要素を持たないリストのインスタンスを生成し、それを返します。
        /// インスタンスを解放するときはクリーンアップのため、`List.deinit`を呼び出してください。
        pub fn init() @This() {
            return .{ .head = null };
        }

        /// 全てのノードを削除します。
        /// リストが持つ値の解放は行いません。
        pub fn deinit(self: *@This(), a: Allocator) void {
            node_utils.clear(a, self.head);
            self.* = undefined;
        }

        /// リストの要素数を数える
        pub fn size(self: @This()) usize {
            return node_utils.size(self.head);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *@This(), a: Allocator) void {
            node_utils.clear(a, self.head);
            self.head = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: @This(), index: usize) ?*Node {
            return node_utils.getNode(self.head, index);
        }

        /// リストの指定した位置の要素を返す。
        pub fn get(self: @This(), index: usize) ?*T {
            return if (self.getNode(index)) |n| &n.value else null;
        }

        /// リストの指定した位置に要素を追加する。
        pub fn add(self: *@This(), a: Allocator, index: usize, value: T) AllocIndexError!void {
            if (index == 0) {
                self.head = try Node.init(a, value, self.head);
                return;
            }

            const node = self.getNode(index - 1) orelse return error.OutOfBounds;
            node.next = try Node.init(a, value, node.next);
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *@This(), a: Allocator, index: usize) IndexError!void {
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

        pub fn iterator(self: @This()) Iterator {
            _ = self;
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            assert(self.isValidList());

            const type_name = "SingleLinearList(" ++ @typeName(T) ++ ")";
            try node_utils.format(w, type_name, self.head);
        }
    };
}

fn ListNode(T: type) type {
    return struct {
        value: T,
        next: ?*@This(),

        /// 値を持つノードのメモリを作成する。
        fn init(a: Allocator, value: T, next: ?*@This()) Allocator.Error!*@This() {
            const node = try a.create(@This());
            node.* = .{ .value = value, .next = next };
            return node;
        }

        /// 値を持つノードのメモリを作成する。
        /// 自分自身をnextに指定する。
        fn initSelf(a: Allocator, value: T) Allocator.Error!*@This() {
            const node = try a.create(@This());
            node.* = .{ .value = value, .next = node };
            return node;
        }

        /// このノードを削除してメモリを解放する。
        fn deinit(node: *@This(), a: Allocator) void {
            a.destroy(node);
        }

        pub fn format(node: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("{}", .{node.value});
        }
    };
}

test SinglyList {
    const L = SinglyList(u8);
    const a = std.testing.allocator;
    const expect = lib.assert.expect;

    var list = L.init();
    defer list.deinit(a);

    try expect(@TypeOf(list) == L(u8));
    try lib.collection.list.test_list.testList(L, &list, a);
    try lib.collection.list.test_list.testRemoveToZero(L, &list, a);
    try lib.collection.list.test_list.testIndexError(L, &list, a);
}

test "format" {
    const L = SinglyList(u8);
    const a = std.testing.allocator;

    var list = L.init();
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
