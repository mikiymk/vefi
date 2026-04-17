const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const assert = lib.assert.assert;

pub fn ListNode(T: type) type {
    return struct {
        value: T,
        next: ?*@This() = null,

        /// 値を持つノードのメモリを作成する。
        fn create(allocator: Allocator, value: T) Allocator.Error!*@This() {
            const node = try allocator.create(@This());
            node.* = .{ .value = value };
            return node;
        }
    };
}

pub fn List(T: type) type {
    return struct {
        pub const Node = ListNode(T);

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        head: ?*Node,

        /// インスタンスを解放するときはクリーンアップのため、`List.deinit`を呼び出してください。
        pub const empty: @This() = .{ .head = null };

        /// 全てのノードを削除します。
        /// リストが持つ値の解放は行いません。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            self.clear(allocator);
            self.* = undefined;
        }

        /// リストの要素数を数える
        pub fn size(self: @This()) usize {
            var node = self.head;
            var count: usize = 0;

            while (node) |n| : (node = n.next) {
                count += 1;
            }

            return count;
        }

        /// 全てのノードを削除します。
        pub fn clear(self: *@This(), allocator: Allocator) void {
            var node = self.head;

            while (node) |n| {
                const next = n.next;
                allocator.destroy(n);
                node = next;
            }

            self.head = null;
        }

        /// `index` 番目のノードを取得する。
        pub fn getNode(self: @This(), index: usize) ?*Node {
            var node = self.head;
            var count = index;

            return while (node) |n| : (node = n.next) {
                if (count == 0) break n;
                count -= 1;
            } else null;
        }

        /// 最も後ろのノードを取得する。
        pub fn getLastNode(self: @This()) ?*Node {
            var node = self.head orelse return null;
            while (node.next) |next| : (node = next) {}
            return node;
        }

        /// `index` 番目の要素の値を取得する。
        pub fn get(self: @This(), index: usize) ?T {
            const node = self.getNode(index) orelse return null;
            return node.value;
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            const node = self.getNode(index) orelse return error.OutOfBounds;
            node.value = value;
        }

        /// 配列の最初に要素を追加する。
        pub fn pushFront(self: *@This(), allocator: Allocator, value: T) Allocator.Error!void {
            const node = try Node.create(allocator, value);
            node.next = self.head;
            self.head = node;
        }

        /// 配列の最後に要素を追加する。
        pub fn pushBack(self: *@This(), allocator: Allocator, value: T) Allocator.Error!void {
            const node = try Node.create(allocator, value);
            if (self.getLastNode()) |prev| {
                prev.next = node;
            } else {
                self.head = node;
            }
        }

        /// 配列の最初の要素を取り出す。
        pub fn popFront(self: *@This(), allocator: Allocator) ?T {
            const node = self.head orelse return null;
            self.head = node.next;
            defer {
                allocator.destroy(node);
            }

            return node.value;
        }

        /// 配列の最後の要素を取り出す。
        pub fn popBack(self: *@This(), allocator: Allocator) ?T {
            const head = self.head orelse return null;
            const pre_last, const last = b: {
                // 最後の1つ前のノードを見つける。
                var prev: ?*Node = null;
                var node = head;

                while (node.next) |n| : (node = n) {
                    prev = node;
                }

                break :b .{ prev, node };
            };

            if (pre_last) |pl| {
                pl.next = null;
            } else {
                self.head = null;
            }

            defer {
                allocator.destroy(last);
            }

            return last.value;
        }

        /// 配列の`index`番目に新しい要素を追加する。
        pub fn add(self: *@This(), allocator: Allocator, index: usize, value: T) AllocIndexError!void {
            if (index == 0) {
                return self.pushFront(allocator, value);
            }
            const prev = self.getNode(index - 1) orelse return error.OutOfBounds;
            const node = try Node.create(allocator, value);
            node.next = prev.next;
            prev.next = node;
        }

        /// リストの指定した位置の要素を削除する。
        pub fn remove(self: *@This(), allocator: Allocator, index: usize) ?T {
            if (index == 0) {
                return self.popFront(allocator);
            } else {
                const prev = self.getNode(index - 1) orelse return null;
                const node = prev.next orelse return null;

                prev.next = node.next;

                defer {
                    allocator.destroy(node);
                }

                return node.value;
            }
        }

        /// スライスにデータをコピーする。
        pub fn toOwnedSlice(self: @This(), allocator: Allocator) Allocator.Error![]T {
            const items = try allocator.alloc(T, self.size());
            var node = self.head;
            var i: usize = 0;
            while (node) |n| : (node = n.next) {
                items[i] = n.value;
                i += 1;
            }

            return items;
        }

        pub const Iterator = struct {};

        pub fn iterator(self: @This()) Iterator {
            _ = self;
        }

        /// 文字列に変換する
        pub fn format(self: @This(), writer: *Writer) Writer.Error!void {
            try writer.print("List(" ++ @typeName(T) ++ "){{", .{});
            var node = self.head;
            var first = true;
            while (node) |n| : (node = n.next) {
                if (first) {
                    try writer.print(" ", .{});
                    first = false;
                } else {
                    try writer.print(", ", .{});
                }

                try writer.print("{}", .{n.value});
            }
            try writer.print(" }}", .{});
        }
    };
}

test List {
    const L = List(usize);
    const a = std.testing.allocator;
    const expect = lib.testing.expect;

    std.log.debug("List test", .{});

    var list = L.empty;
    defer list.deinit(a);

    try expect(list.size()).is(0);
    try expect(list.get(0)).isNull();

    try list.add(a, 0, 1);
    try list.add(a, 1, 2);
    try list.add(a, 2, 3);
    try expect(list.size()).is(3);
    try expect(list.get(1)).opt().is(2);
    try expect(list.get(3)).isNull();

    try expect(list.remove(a, 1)).is(2);
    try expect(list.remove(a, 3)).isNull();
    try expect(list.size()).is(2);
    try expect(list.get(2)).isNull();

    list.clear(a);
    try expect(list.size()).is(0);

    try list.pushBack(a, 1);
    try list.pushBack(a, 2);
    try expect(list.popBack(a)).opt().is(2);
    try expect(list.popBack(a)).opt().is(1);
    try expect(list.popBack(a)).isNull();

    try list.pushFront(a, 3);
    try list.pushFront(a, 4);
    try expect(list.popFront(a)).opt().is(4);
    try expect(list.popFront(a)).opt().is(3);
    try expect(list.popFront(a)).isNull();
}

test "format" {
    const L = List(u8);
    const a = std.testing.allocator;
    const expect = lib.testing.expect;

    var list = L.empty;
    defer list.deinit(a);

    try list.pushBack(a, 1);
    try list.pushBack(a, 2);
    try list.pushBack(a, 3);
    try list.pushBack(a, 4);
    try list.pushBack(a, 5);

    const format = try std.fmt.allocPrint(a, "{f}", .{list});
    defer a.free(format);

    try expect(format).isString("List(u8){ 1, 2, 3, 4, 5 }");
}
