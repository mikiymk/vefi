const std = @import("std");
const lib = @import("../../root.zig");
const node_utils = lib.collection.list.node;

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub const ListOption = struct {
    circular: bool = false,
    doubly: bool = false,
    has_sentinel: bool = false,
    has_tail: bool = false,
};

pub fn GeneralListNode(T: type, options: ListOption) type {
    return struct {
        const Node = @This();
        const NodeRef = if (options.circular or options.has_sentinel) ?*Node else *Node;
        pub const Item = T;

        value: Item,
        next: NodeRef,
        prev: if (options.doubly) NodeRef else void,

        /// 値を持つノードのメモリを作成する。
        pub fn init(a: Allocator, value: T) Allocator.Error!*Node {
            const node = try a.create(Node);
            node.value = value;
            return node;
        }

        /// 値を持つノードのメモリを作成する。
        /// 自分自身をnextに指定する。
        fn initSelf(a: Allocator, value: T) Allocator.Error!*Node {
            const node = try a.create(Node);
            node.value = value;
            node.next = node;
            if (options.doubly) node.prev = node;
            return node;
        }

        /// このノードを削除してメモリを解放する。
        pub fn deinit(node: *Node, a: Allocator) void {
            a.destroy(node);
        }

        /// このノードの値を書き込む。
        pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("{}", .{node.value});
        }
    };
}

pub fn GeneralList(T: type, options: ListOption) type {
    return struct {
        const List = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Node = GeneralListNode(T, options);
        const NodeRef = if (options.circular or options.has_sentinel) ?*Node else *Node;

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: if (options.has_sentinel)
*Node 
else 
?*Node,
        tail: if (!options.has_tail) 
void 
else if (options.has_sentinel)
*Node 
else 
?*Node,
        sentinel: if (options.has_sentinel) 
*Node 
else 
void,

        /// 新しい要素を持たないリストのインスタンスを生成し、それを返します。
        /// インスタンスを解放するときはクリーンアップのため、`List.deinit`を呼び出してください。
        pub fn init(a: Allocator) List {
            var list = undefined;
            if (options_has_sentinel) {
                list.sentinel = Node.init(a);
                list.head = list.sentinel;
                if (has_tail) list.tail = list.sentinel;
            } else {
                list.head = null;
                if (has_tail) list.tail = null;
            }
            return list;
        }

        /// 全てのノードを削除します。
        /// リストが持つ値の解放は行いません。
        pub fn deinit(self: *List, a: Allocator) void {
            if (options.has_sentinel) {
                return node_utils.sentinel.clear(a, self.head, self.sentinel);
            } else if (options.circular) {
                return node_utils.circular.clear(a, self.head);
            } else {
                return node_utils.linear.clear(a, self.head);
            }
            self.* = undefined;
        }

        /// リストの構造が正しいか確認する。
        fn isValidList(self: List) bool {
            _ = self;
            return true;
        }

        /// リストの要素数を数える
        pub fn size(self: List) usize {
            assert(self.isValidList());

            return node_utils.size(self.head);
        }

        /// リストの全ての要素を削除する。
        pub fn clear(self: *List, a: Allocator) void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            node_utils.clear(a, self.head);
            self.head = null;
        }

        /// リストの指定した位置のノードを返す。
        fn getNode(self: List, index: usize) NodeRef {
            assert(self.isValidList());

            return node_utils.getNode(self.head, index);
        }

        /// リストの先頭のノードを返す。
        fn getFirstNode(self: List) NodeRef {
            assert(self.isValidList());

            return self.head;
        }

        /// リストの末尾のノードを返す。
        fn getLastNode(self: List) NodeRef {
            assert(self.isValidList());

            if (options.has_tail) {
                return self.tail;
            } else if (options.has_sentinel) {
                return node_utils.sentinel.getLastNode(self.head, self.sentinel);
            } else if (options.circular) {
                return node_utils.circular.getLastNode(self.head);
            } else {
                return node_utils.linear.getLastNode(self.head);
            }
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
        pub fn add(self: *List, a: Allocator, index: usize, value: T) AllocIndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.addFirst(a, value);
            }

            const node = self.getNode(index - 1) orelse return error.OutOfBounds;
            node.next = try Node.init(a, value, node.next);
        }

        /// リストの先頭に要素を追加する。
        pub fn addFirst(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            self.head = try Node.init(a, value, self.head);
        }

        /// リストの末尾に要素を追加する。
        pub fn addLast(self: *List, a: Allocator, value: T) Allocator.Error!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = try Node.init(a, value, null);
            if (self.getLastNode()) |prev| {
                prev.next = node;
            } else {
                self.head = node;
            }
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *List, a: Allocator, index: usize) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            if (index == 0) {
                return self.removeFirst(a);
            }

            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            const node = prev.next orelse return error.OutOfBounds;

            prev.next = node.next;
            node.deinit(a);
        }

        /// リストの先頭の要素を削除する。
        pub fn removeFirst(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const node = self.head orelse return error.OutOfBounds;

            self.head = node.next;
            node.deinit(a);
        }

        /// リストの末尾の要素を削除する。
        pub fn removeLast(self: *List, a: Allocator) IndexError!void {
            assert(self.isValidList());
            defer assert(self.isValidList());

            const prev_last = node_utils.getLastNode2(self.head);
            const last = if (prev_last) |pl| pl.next else self.head;
            
            if (last) |l| {
                l.deinit(a);
            } else {
                return error.OutOfBounds;
            }

            if (prev_last) |pl| {
                pl.next = null;
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
            assert(self.isValidList());

            const type_name = "SingleLinearList(" ++ @typeName(T) ++ ")";
            try node_utils.format(w, type_name, self.head);
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
