const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const Range = lib.collection.Range;

/// 動的配列 (Dynamic Array)
pub fn DynamicArray(T: type) type {
    return struct {
        pub const IndexError = error{OutOfBounds};
        pub const AllocError = Allocator.Error;
        pub const AllocIndexError = AllocError || IndexError;

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
        pub fn isInBound(self: @This(), index: usize) bool {
            return 0 <= index and index < self._size;
        }

        /// インデックス範囲が配列の範囲内かどうか判定する。
        pub fn isInBoundRange(self: @This(), range: Range) bool {
            return 0 <= range.begin and range.begin < self._size and
                0 < range.end and range.end <= self._size and
                range.begin < range.end;
        }

        /// 配列の要素数を返す。
        pub fn size(self: @This()) usize {
            return self._size;
        }

        /// 配列の`index`番目の要素を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?T {
            if (!self.isInBound(index)) return null;
            return self._values[index];
        }

        /// 配列の`index`番目の要素への参照を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn getRef(self: @This(), index: usize) ?*T {
            if (!self.isInBound(index)) return null;
            return @ptrCast(self._values.ptr + index);
        }

        /// 配列の範囲の要素のスライスを返す。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn slice(self: @This(), range: Range) IndexError![]const T {
            if (!self.isInBoundRange(range)) return error.OutOfBounds;
            const begin, const end = range;

            return self._values[begin..end];
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            if (!self.isInBound(index)) return error.OutOfBounds;
            self._values[index] = value;
        }

        /// 配列の`index`番目から先を新しい値のスライスで更新する。
        /// `index`からスライスの範囲が配列の範囲外の場合、エラーを返す。
        pub fn setAll(self: *@This(), index: usize, values: []const T) IndexError!void {
            if (!self.isInBoundRange(.{ index, index + values.len })) return error.OutOfBounds;
            @memcpy(self._values[index..][0..values.len], values);
        }

        /// 配列の`begin`番目(含む)から`end`番目(含まない)の要素の値をまとめて設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn setFill(self: *@This(), range: Range, value: T) IndexError!void {
            if (!self.isInBoundRange(range)) return error.OutOfBounds;
            @memset(self._values[range.begin..range.end], value);
        }

        /// 配列の`left`番目と`right`番目の要素の値を交換する。
        /// `left`か`right`が配列の範囲外の場合、エラーを返す。
        pub fn swap(self: *@This(), left: usize, right: usize) IndexError!void {
            if (!self.isInBound(left)) return error.OutOfBounds;
            if (!self.isInBound(right)) return error.OutOfBounds;

            const tmp = self.get(left);
            self.set(left, self.get(right));
            self.set(right, tmp);
        }

        /// 配列の要素の並びを逆転する。
        pub fn reverse(self: @This()) void {
            for (0..(self._size() / 2)) |i| {
                self.swap(i, self._size - 1);
            }
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn pushFront(self: *@This(), allocator: Allocator, item: T) Allocator.Error!void {
            try self.insert(allocator, 0, item);
        }

        pub fn pushFrontAll() a {}

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn pushBack(self: *@This(), allocator: Allocator, item: T) Allocator.Error!void {
            if (self._values.len <= self._size) {
                try self.extendSize(allocator);
            }

            self._values[self._size] = item;
            self._size += 1;
        }

        /// 複数の値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn pushBackAll(self: *@This(), allocator: Allocator, item: []const T) Allocator.Error!void {
            if (self._values.len <= self.size() + item.len - 1) {
                try self.extendSize(allocator);
            }
            const index = self.size();
            self._size += item.len;
            try self.setAll(index, item);
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
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
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

        pub fn insertAll() a {}

        /// 配列の`index`番目の要素を削除する。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn delete(self: *@This(), index: usize) ?T {
            const value = self.get(index) orelse return null;

            self._size -= 1;
            for (self._values[index..self._size], self._values[(index + 1)..(self._size + 1)]) |*e, f| {
                e.* = f;
            }

            return value;
        }

        /// 同じ要素を持つ配列を複製する。
        pub fn copy(self: @This(), allocator: Allocator) AllocError!@This() {
            const new_array: @This() = .{
                ._size = self._size,
                ._values = try self.copyToSlice(allocator),
            };

            return new_array;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self._values[0..self._size];
        }

        /// 配列をコピーした新しいスライスを作成する。
        pub fn copyToSlice(self: @This(), allocator: Allocator) Allocator.Error![]const T {
            var new_slice = try allocator.alloc(T, self._size);
            @memcpy(new_slice[0..], self.asSlice());

            return new_slice;
        }

        /// 配列のキャパシティーを指定したサイズ以上に拡張する。
        pub fn reserve(self: *@This(), allocator: Allocator, min_size: usize) Allocator.Error!void {
            const allocate_size = blk: {
                var s: usize = 8;
                while (true) {
                    if (min_size <= s) break :blk s;
                    s <<= 1;
                }
            };
            if (allocate_size < self._values.len)
                return;

            self._values = try allocator.realloc(self._values, allocate_size);
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
    try eq(array.get(3), null);

    try eq(array.getRef(1).?.*, 6);
    try eq(array.getRef(3), null);

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
