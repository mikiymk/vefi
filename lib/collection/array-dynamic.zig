const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const Range = lib.collection.array.Range;

/// 動的配列 (Dynamic Array)
pub fn DynamicArray(T: type) type {
    return struct {
        _values: []T,
        _size: usize,

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{ ._values = &[_]T{}, ._size = 0 };
        }

        /// すべてのメモリを解放する。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self._values);
            self.* = undefined;
        }

        /// インデックスが配列の範囲内かどうか判定する。
        pub fn isInBoundIndex(self: @This(), index: usize) bool {
            return 0 <= index and index < self._size;
        }

        /// インデックス範囲が配列の範囲内かどうか判定する。
        pub fn isInBoundRange(self: @This(), range: Range) bool {
            return 0 <= range.begin and range.begin < self._size and 0 < range.end and range.end <= self._size and range.begin < range.end;
        }

        /// インデックスがが配列の範囲内かどうかチェックをする。
        /// 配列の範囲外の場合、未定義動作を起こす。
        pub fn assertBound(self: @This(), index: usize) void {
            assert(self.isInBoundIndex(index));
        }

        /// 配列の要素数を返す。
        pub fn size(self: @This()) usize {
            return self._size;
        }

        /// 配列の`index`番目の要素を返す。
        /// 配列の範囲外の場合、未定義動作を起こす。
        pub fn get(self: @This(), index: usize) T {
            self.assertBound(index);
            return self._values[index];
        }

        /// 配列の`index`番目の要素への参照を返す。
        /// 配列の範囲外の場合、未定義動作を起こす。
        pub fn getRef(self: @This(), index: usize) *T {
            self.assertBound(index);
            return @ptrCast(self._values.ptr + index);
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// 配列の範囲外の場合、未定義動作を起こす。
        pub fn set(self: *@This(), index: usize, value: T) void {
            self.assertBound(index);
            self._values[index] = value;
        }

        /// 配列の`begin`〜`end - 1`番目の要素の値をまとめて設定する。
        /// `begin >= end`や配列の範囲外の場合、未定義動作を起こす。
        pub fn fill(self: *@This(), range: Range, value: T) void {
            assert(self.isInBoundRange(range));

            @memset(self._values[range.begin..range.end], value);
        }

        /// 配列の`left`番目と`right`番目の要素の値を交換する。
        /// 配列の範囲外の場合、未定義動作を起こす。
        pub fn swap(self: *@This(), left: usize, right: usize) void {
            self.assertBound(left);
            self.assertBound(right);

            const tmp = self.get(left);
            self.set(left, self.get(right));
            self.set(right, tmp);
        }

        /// 配列の要素の並びを逆転する。
        pub fn reverse(self: @This()) usize {
            for (0..(self._size() / 2)) |i| {
                self.swap(i, self._size - 1);
            }
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        pub fn pushFront(self: *@This(), allocator: Allocator, item: T) Allocator.Error!void {
            try self.insert(allocator, 0, item);
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        pub fn pushBack(self: *@This(), allocator: Allocator, item: T) Allocator.Error!void {
            if (self._values.len <= self._size) {
                try self.extendSize(allocator);
            }

            self._values[self._size] = item;
            self._size += 1;
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn popFront(self: *@This()) ?T {
            return self.delete(0);
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn popBack(self: *@This()) ?T {
            if (self._size == 0) return null;
            self._size -= 1;
            return self._values[self._size];
        }

        /// 配列の`index`番目に新しい要素を追加する。
        pub fn insert(self: *@This(), allocator: Allocator, index: usize, item: T) Allocator.Error!void {
            if (self._values.len <= self._size) {
                try self.extendSize(allocator);
            }

            self._size += 1;

            var value = item;
            for (self._values[index..self._size]) |*e| {
                const tmp = value;
                value = e.*;
                e.* = tmp;
            }
        }

        /// 配列の`index`番目の要素を削除する。
        pub fn delete(self: *@This(), index: usize) ?T {
            const value = self.get(index);

            self._size -= 1;
            for (self._values[index..self._size], self._values[(index + 1)..(self._size + 1)]) |*e, f| {
                e.* = f;
            }

            return value;
        }

        pub fn clone(self: @This(), allocator: Allocator) @This() {
            const new_array = init();
            new_array._size = self._size;
            new_array._values = self.copyToSlice(allocator);

            return new_array;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self._values[0..self._size];
        }

        /// 配列を新しいスライスにコピーする。
        pub fn copyToSlice(self: @This(), allocator: Allocator) Allocator.Error![]const T {
            var slice = try allocator.alloc(T, self._size);
            @memcpy(slice[0..self._size], self._values[0..self._size]);

            return slice;
        }

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) Allocator.Error!void {
            const extend_factor = 2;
            const initial_length = 8;

            const length = self._values.len;
            const new_length: usize = if (length == 0) initial_length else length * extend_factor;

            self._values = try allocator.realloc(self._values, new_length);
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("DynamicArray({s}){{", .{@typeName(T)});

            var first = true;
            for (self._values[0..self._size]) |value| {
                if (first) {
                    try writer.print(" ", .{});
                    first = false;
                } else {
                    try writer.print(", ", .{});
                }

                try writer.print("{}", .{value});
            }

            try writer.print(" }}", .{});
        }
    };
}

test DynamicArray {
    const allocator = std.testing.allocator;
    const DA = DynamicArray(u8);
    const eq = lib.assert.expectEqualStruct;

    var array = DA.init();
    defer array.deinit(allocator);

    try array.pushBack(allocator, 5);
    try eq(array.asSlice(), &.{5});

    try array.pushBack(allocator, 6);
    try array.pushBack(allocator, 7);
    try eq(array.asSlice(), &.{ 5, 6, 7 });

    try eq(array.popBack(), 7);
    try eq(array.popBack(), 6);
    try eq(array.popBack(), 5);
    try eq(array.popBack(), null);
    try eq(array.asSlice(), &.{});

    try array.pushBack(allocator, 5);
    try array.pushBack(allocator, 6);
    try array.pushBack(allocator, 7);
    try eq(array.asSlice(), &.{ 5, 6, 7 });

    try eq(array.get(1), 6);
    // try eq(array.get(3), null);

    try eq(array.getRef(1).*, 6);
    // try eq(array.getRef(3), null);

    try array.insert(allocator, 1, 10);
    try eq(array.asSlice(), &.{ 5, 10, 6, 7 });

    try eq(array.delete(1), 10);
    try eq(array.asSlice(), &.{ 5, 6, 7 });

    const slice = try array.copyToSlice(allocator);
    defer allocator.free(slice);
    try eq(slice, &.{ 5, 6, 7 });
}

test "format" {
    const Array = DynamicArray(u8);
    const a = std.testing.allocator;

    var array = Array.init();
    defer array.deinit(a);

    try array.pushBack(a, 1);
    try array.pushBack(a, 2);
    try array.pushBack(a, 3);
    try array.pushBack(a, 4);
    try array.pushBack(a, 5);

    const format = try std.fmt.allocPrint(a, "{}", .{array});
    defer a.free(format);

    try lib.assert.expectEqualString("DynamicArray(u8){ 1, 2, 3, 4, 5 }", format);
}
