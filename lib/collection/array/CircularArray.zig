const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const Range = lib.collection.Range;
const copyInSlice = lib.collection.copyInSlice;

/// 環状配列
/// 最初と最後の要素の追加・削除が高速にできる。
pub fn CircularArray(T: type) type {
    return struct {
        pub const Item = T;

        pub const IndexError = error{OutOfBounds};
        pub const OverflowError = error{Overflow};
        pub const OverIndexError = OverflowError || IndexError;
        pub const AllocIndexError = Allocator.Error || IndexError;

        items: []T,
        /// popで移動する
        head: usize,
        /// pushで移動する
        tail: usize,

        // 1. head < tail
        //   length 6 size 4
        //   [0 1 2 3 4 5] (6) phy
        //   [5 0 1 2 3 4]     log
        //      ^head   ^
        //              ^tail

        // 2. head > tail
        //   length 6 size 4
        //   [0 1 2 3 4 5] (6) phy
        //   [2 3 4 5 0 1]     log
        //        ^   ^head
        //        ^tail

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{
                .items = &.{},
                .head = 0,
                .tail = 0,
            };
        }

        /// すべてのメモリを解放する。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.items);
            self.* = undefined;
        }

        /// 配列の要素数を返す。
        pub fn size(self: @This()) usize {
            if (self.head < self.tail) {
                // length 6 size 4
                // [0 1 2 3 4 5] (6)
                //    ^head   ^
                //            ^tail
                return self.tail - self.head;
            } else {
                // length 6 size 4
                // [0 1 2 3 4 5] (6)
                //      ^   ^head
                //      ^tail
                return (self.items.len - self.head) + self.tail;
            }
        }

        /// 配列の要素を全てなくす。
        pub fn clear(self: *@This()) void {
            self.tail = self.head;
        }

        /// インデックスが配列の範囲内かどうか判定する。
        pub fn isInBound(self: @This(), index: usize) bool {
            return index < self.size();
        }

        /// 内部配列のインデックスに変換する
        fn internalIndex(self: @This(), index: usize) IndexError!usize {
            if (!self.isInBound(index)) {
                return error.OutOfBounds;
            }

            const remain = self.items.len - self.head;
            if (index < remain) {
                return self.head + index;
            } else {
                return index - remain;
            }
        }

        /// 配列の`index`番目の要素を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?*T {
            return &self.items[self.internalIndex(index) catch return null];
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            const internal_index = try self.internalIndex(index);
            self.items[internal_index] = value;
        }

        /// 配列の末尾に要素を加える。
        pub fn push(self: *@This(), allocator: Allocator, value: T) Allocator.Error!void {
            if (self.items.len <= self.size() + 1) {
                try self.extendSize(allocator);
            }

            self.items[self.tail] = value;
            self.tail += 1;
            if (self.tail == self.items.len) {
                self.tail = 0;
            }
        }

        /// 配列の先頭の要素を取り出す。
        pub fn pop(self: *@This()) ?T {
            if (self.size() == 0) {
                return null;
            }

            defer {
                self.head += 1;
                if (self.head == self.items.len) {
                    self.head = 0;
                }
            }
            return self.items[self.head];
        }

        /// 配列の`index`番目に新しい要素を追加する。
        pub fn add(self: *@This(), allocator: Allocator, index: usize, item: T) AllocIndexError!void {
            if (self.items.len <= self.size() + 1) {
                try self.extendSize(allocator);
            }

            const i = try self.internalIndex(index);

            if (i < self.tail) {
                @memmove(self.items[i + 1 .. self.tail + 1], self.items[i..self.tail]);
            } else {
                @memmove(self.items[1 .. self.tail + 1], self.items[0..self.tail]);
                self.items[0] = self.items[self.items.len - 1];
                @memmove(self.items[i + 1 .. self.items.len], self.items[i .. self.items.len - 1]);
            }
            self.items[i] = item;
            self.tail += 1;
            if (self.tail == self.items.len) {
                self.tail = 0;
            }
        }

        /// 配列の`index`番目の要素を削除する。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn remove(self: *@This(), index: usize) ?T {
            const i = self.internalIndex(index) catch return null;
            const value = self.items[i];

            if (self.head <= i) {
                @memmove(self.items[self.head + 1 .. i + 1], self.items[self.head..i]);
            } else {
                @memmove(self.items[1 .. i + 1], self.items[0..i]);
                self.items[0] = self.items[self.items.len - 1];
                @memmove(self.items[self.head + 1 .. self.items.len], self.items[self.head .. self.items.len - 1]);
            }

            self.head += 1;
            if (self.head == self.items.len) {
                self.head = 0;
            }
            return value;
        }

        pub fn toOwnedSlice(self: @This(), allocator: Allocator) Allocator.Error![]T {
            const items = try allocator.alloc(T, self.size());
            self.copyToBuffer(items);
            return items;
        }

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) Allocator.Error!void {
            const extend_factor = 2;
            const initial_length = 8;

            const length = self.items.len;
            const new_length: usize = if (length == 0) initial_length else length * extend_factor;

            const new_items = try allocator.alloc(T, new_length);
            const copy_size = self.size();

            self.copyToBuffer(new_items[0..copy_size]);

            self.head = 0;
            self.tail = copy_size;
            allocator.free(self.items);
            self.items = new_items;
        }

        fn copyToBuffer(self: @This(), buffer: []T) void {
            if (self.head <= self.tail) {
                @memcpy(buffer, self.items[self.head..self.tail]);
            } else {
                const copy_size_1 = self.items.len - self.head;
                @memcpy(buffer[0..copy_size_1], self.items[self.head..]);
                @memcpy(buffer[copy_size_1..], self.items[0..self.tail]);
            }
        }

        fn Iterator(U: type) type {
            _ = U;
            return void;
        }

        pub fn iterator(self: *@This()) Iterator(@This()) {
            return .{ .array = self };
        }

        const Writer = std.Io.Writer;
        // 文字列に変換する
        pub fn format(self: @This(), writer: *Writer) Writer.Error!void {
            try writer.writeAll("CircularArray(" ++ @typeName(T) ++ "){");

            if (self.head <= self.tail) {
                for (self.items[self.head..self.tail], 0..) |value, i| {
                    try writer.print("{s}{}", .{ if (i == 0) " " else ", ", value });
                }
            } else {
                for (self.items[self.head..], 0..) |value, i| {
                    try writer.print("{s}{}", .{ if (i == 0) " " else ", ", value });
                }
                for (self.items[0..self.tail]) |value| {
                    try writer.print("{s}{}", .{ ", ", value });
                }
            }
            try writer.writeAll(" }");
        }
    };
}

const expect = lib.testing.expect;

test CircularArray {
    const ta = std.testing.allocator;
    const TA = CircularArray(usize);

    var array = TA.init();
    defer array.deinit(ta);

    try expect(array.size()).is(0);
    try expect(array.get(0)).isNull();

    try array.push(ta, 1);
    try array.push(ta, 2);
    try array.push(ta, 3);
    try array.push(ta, 4);
    try array.push(ta, 5);
    {
        const slice = try array.toOwnedSlice(ta);
        defer ta.free(slice);
        try expect(slice).isSlice(usize, &.{ 1, 2, 3, 4, 5 });
    }

    try expect(array.pop()).opt().is(1);
    try expect(array.pop()).opt().is(2);
    try expect(array.pop()).opt().is(3);
    {
        const slice = try array.toOwnedSlice(ta);
        defer ta.free(slice);
        try expect(slice).isSlice(usize, &.{ 4, 5 });
    }

    try expect(array.get(0)).opt().ptr().is(4);
    try expect(array.get(1)).opt().ptr().is(5);

    try array.push(ta, 6);
    try array.push(ta, 7);
    try array.push(ta, 8);
    try expect(array.pop()).opt().is(4);
    try expect(array.pop()).opt().is(5);
    try expect(array.pop()).opt().is(6);
    {
        const slice = try array.toOwnedSlice(ta);
        defer ta.free(slice);
        try expect(slice).isSlice(usize, &.{ 7, 8 });
    }

    try array.add(ta, 0, 10);
    try array.add(ta, 1, 11);
    try array.add(ta, 2, 12);
    try expect(array.remove(1)).opt().is(11);
    try expect(array.remove(1)).opt().is(12);
    try expect(array.remove(0)).opt().is(10);
    {
        const slice = try array.toOwnedSlice(ta);
        defer ta.free(slice);
        try expect(slice).isSlice(usize, &.{ 7, 8 });
    }

    try array.push(ta, 1);
    try array.push(ta, 2);
    try array.push(ta, 3);
    try array.push(ta, 4);
    try array.push(ta, 5);
    try array.push(ta, 6);
    {
        const slice = try array.toOwnedSlice(ta);
        defer ta.free(slice);
        try expect(slice).isSlice(usize, &.{ 7, 8, 1, 2, 3, 4, 5, 6 });
    }
    try expect(array.items.len).is(16);
    try expect(array.items[0..8]).isSlice(usize, &.{ 7, 8, 1, 2, 3, 4, 5, 6 });
}

test "format" {
    const Array = CircularArray(u8);
    const a = std.testing.allocator;

    {
        const array = Array{ .items = &.{}, .head = 0, .tail = 0 };
        const format = try std.fmt.allocPrint(a, "{f}", .{array});
        defer a.free(format);
        try expect(format).isString("CircularArray(u8){ }");
    }

    {
        var slice = [_]u8{ 0, 1, 2, 3, 0 };
        const array = Array{ .items = &slice, .head = 1, .tail = 4 };
        const format = try std.fmt.allocPrint(a, "{f}", .{array});
        defer a.free(format);
        try expect(format).isString("CircularArray(u8){ 1, 2, 3 }");
    }

    {
        var slice = [_]u8{ 3, 4, 0, 0, 1, 2 };
        const array = Array{ .items = &slice, .head = 4, .tail = 2 };
        const format = try std.fmt.allocPrint(a, "{f}", .{array});
        defer a.free(format);
        try expect(format).isString("CircularArray(u8){ 1, 2, 3, 4 }");
    }
}
