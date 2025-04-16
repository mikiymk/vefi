const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const Range = lib.collection.Range;

/// - アロケーターを使わない動的配列
/// - 静的配列と長さを持つ
pub fn StaticDynamicArray(T: type, max_length: usize) type {
    return struct {
        pub const Item = T;

        pub const IndexError = error{OutOfBounds};
        pub const OverflowError = error{Overflow};
        pub const OverIndexError = OverflowError || IndexError;

        values: [max_length]T,
        length: usize,

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{ .values = undefined, .length = 0 };
        }

        /// インデックスが配列の範囲内かどうか判定する。
        pub fn isInBound(self: @This(), index: usize) bool {
            const size_ = self.size();

            return 0 <= index and index < size_;
        }

        /// インデックス範囲が配列の範囲内かどうか判定する。
        pub fn isInBoundRange(self: @This(), range: Range) bool {
            const begin, const end = range;
            const size_ = self.size();

            return 0 <= begin and begin < size_ and
                0 < end and end <= size_ and
                begin < end;
        }

        /// 配列の要素数を返す。
        pub fn size(self: @This()) usize {
            return self.length;
        }

        /// 配列の要素を全てなくす。
        pub fn clear(self: *@This()) void {
            self.length = 0;
        }

        /// 配列の`index`番目の要素を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?T {
            if (!self.isInBound(index)) return null;
            return self.values[index];
        }

        /// 配列の`index`番目の要素への参照を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn getRef(self: @This(), index: usize) ?*T {
            if (!self.isInBound(index)) return null;
            return @ptrCast(self.values.ptr + index);
        }

        /// 配列の範囲の要素のスライスを返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn slice(self: @This(), range: Range) ?[]const T {
            if (!self.isInBoundRange(range)) return null;
            const begin, const end = range;

            return self.values[begin..end];
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            if (!self.isInBound(index)) return error.OutOfBounds;
            self.values[index] = value;
        }

        /// 配列の`index`番目から先を新しい値のスライスで更新する。
        /// `index`からスライスの範囲が配列の範囲外の場合、エラーを返す。
        pub fn setAll(self: *@This(), index: usize, values: []const T) IndexError!void {
            if (!self.isInBoundRange(.{ index, index + values.len })) return error.OutOfBounds;
            @memcpy(self.values[index..][0..values.len], values);
        }

        /// 配列の`begin`番目(含む)から`end`番目(含まない)の要素の値をまとめて設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn setFill(self: *@This(), range: Range, value: T) IndexError!void {
            if (!self.isInBoundRange(range)) return error.OutOfBounds;
            const begin, const end = range;
            @memset(self.values[begin..end], value);
        }

        fn copyInArray(self: *@This(), src: usize, dst: usize, length: usize) IndexError!void {
            const src_end = src + length;
            const dst_end = dst + length;

            if (src == dst or length == 0) return; // 何もしない場合
            if (!self.isInBoundRange(.{ src, src_end })) return error.OutOfBounds;
            if (!self.isInBoundRange(.{ dst, dst_end })) return error.OutOfBounds;

            const dst_slice = self.values[dst..dst_end];
            const src_slice = self.values[src..src_end];

            if (src_end < dst or dst_end < src) {
                @memcpy(dst_slice, src_slice);
            } else if (src < dst) {
                var i = dst_slice.len;
                while (i != 0) : (i -= 1) {
                    dst_slice[i - 1] = src_slice[i - 1];
                }
            } else {
                for (dst_slice, src_slice) |*d, s| {
                    d.* = s;
                }
            }
        }

        /// 配列の`left`番目と`right`番目の要素の値を交換する。
        /// `left`か`right`が配列の範囲外の場合、エラーを返す。
        pub fn swap(self: *@This(), left: usize, right: usize) IndexError!void {
            if (!self.isInBound(left)) return error.OutOfBounds;
            if (!self.isInBound(right)) return error.OutOfBounds;

            const tmp = self.get(left).?;
            self.set(left, self.get(right).?) catch unreachable;
            self.set(right, tmp) catch unreachable;
        }

        /// 配列の要素の並びを逆転する。
        pub fn reverse(self: *@This()) void {
            for (0..(self.size() / 2)) |i| {
                self.swap(i, self.size() - i - 1) catch unreachable;
            }
        }

        /// 配列の`index`番目に新しい要素を追加する。
        /// 配列の長さが足りないときはエラーを返す。
        pub fn add(self: *@This(), index: usize, item: T) OverIndexError!void {
            if (self.values.len <= self.length) {
                return error.Overflow;
            }

            self.length += 1;
            try self.copyInArray(index, index + 1, self.size() - index - 1);
            self.values[index] = item;
        }

        pub fn addAll(self: *@This(), index: usize, items: []const T) OverIndexError!void {
            if (self.values.len < self.size() + items.len) {
                return error.Overflow;
            }

            const index_end = index + items.len;
            self.length += items.len;
            try self.copyInArray(index, index_end, self.size() - index_end);
            try self.setAll(index, items);
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn addFirst(self: *@This(), allocator: Allocator, item: T) OverflowError!void {
            self.add(allocator, 0, item) catch |err| switch (err) {
                error.OutOfBounds => unreachable,
                else => |e| return e,
            };
        }

        pub fn addFirstAll(self: *@This(), items: []const T) OverflowError!void {
            self.addAll(allocator, 0, items) catch |err| switch (err) {
                error.OutOfBounds => unreachable,
                else => |e| return e,
            };
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn addLast(self: *@This(), allocator: Allocator, item: T) OverflowError!void {
            if (self.values.len <= self.length) {
                return error.Overflow;
            }

            self.values[self.length] = item;
            self.length += 1;
        }

        /// 複数の値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn addLastAll(self: *@This(), allocator: Allocator, items: []const T) OverflowError!void {
            if (self.values.len < self.size() + items.len) {
                return error.Overflow;
            }

            const index = self.size();
            self.length += items.len;
            self.setAll(index, items) catch unreachable;
        }

        /// 配列の`index`番目の要素を削除する。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn remove(self: *@This(), index: usize) ?T {
            const value = self.get(index) orelse return null;

            try self.copyInArray(index + 1, index, self.size() - index - 1);
            self.length -= 1;
            return value;
        }

        pub fn removeAll(self: *@This(), index: usize, length: usize) IndexError!void {
            const src_begin = index + length;
            try self.copyInArray(src_begin, index, self.size() - src_begin);
            self.length -= length;
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn removeFirst(self: *@This()) ?T {
            return self.remove(0);
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn removeLast(self: *@This()) ?T {
            if (self.length == 0) return null;
            self.length -= 1;
            return self.values[self.length];
        }

        /// 同じ要素を持つ配列を複製する。
        pub fn copy(self: @This()) @This() {
            return self;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self.values[0..self.length];
        }

        /// 配列をコピーした新しいスライスを作成する。
        pub fn copyToSlice(self: @This(), allocator: Allocator) Allocator.Error![]const T {
            var new_slice = try allocator.alloc(T, self.length);
            @memcpy(new_slice[0..], self.asSlice());

            return new_slice;
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("StaticDynamicArray({s}){{", .{@typeName(T)});

            var first = true;
            for (self.values[0..self.length]) |value| {
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
    const Array = StaticDynamicArray(usize, 20);
    const expect = lib.testing.expect;

    var array = Array.init();
    defer array.deinit(allocator);

    try expect(array.asSlice()).isSlice(usize, &.{});
    try expect(array.size()).is(0);
    try expect(array.get(0)).isNull();
    try expect(array.getRef(0)).isNull();
    try expect(array.slice(.{ 0, 1 })).isNull();

    try array.addLast(allocator, 1);
    try array.addLast(allocator, 2);
    try array.addLast(allocator, 3);
    try array.addLast(allocator, 4);
    try array.addLast(allocator, 5);
    try expect(array.asSlice()).isSlice(usize, &.{ 1, 2, 3, 4, 5 });

    try array.addFirst(allocator, 6);
    try array.addFirst(allocator, 7);
    try array.addFirst(allocator, 8);
    try expect(array.asSlice()).isSlice(usize, &.{ 8, 7, 6, 1, 2, 3, 4, 5 });

    try expect(array.removeLast()).is(5);
    try expect(array.removeFirst()).is(8);
    try expect(array.asSlice()).isSlice(usize, &.{ 7, 6, 1, 2, 3, 4 });

    try array.add(allocator, 5, 9);
    try array.add(allocator, 0, 10);
    try array.add(allocator, 8, 11);
    try expect(array.asSlice()).isSlice(usize, &.{ 10, 7, 6, 1, 2, 3, 9, 4, 11 });

    try expect(array.remove(4)).is(2);
    try expect(array.remove(100)).isNull();
    try expect(array.asSlice()).isSlice(usize, &.{ 10, 7, 6, 1, 3, 9, 4, 11 });

    try array.set(3, 12);
    try expect(array.set(100, 13)).isError(error.OutOfBounds);
    try expect(array.asSlice()).isSlice(usize, &.{ 10, 7, 6, 12, 3, 9, 4, 11 });

    try array.setAll(5, &.{ 14, 15, 16 });
    try expect(array.setAll(6, &.{ 17, 18, 19 })).isError(error.OutOfBounds);
    try expect(array.asSlice()).isSlice(usize, &.{ 10, 7, 6, 12, 3, 14, 15, 16 });

    try array.setFill(.{ 2, 4 }, 20);
    try expect(array.setFill(.{ 5, 100 }, 21)).isError(error.OutOfBounds);
    try expect(array.asSlice()).isSlice(usize, &.{ 10, 7, 20, 20, 3, 14, 15, 16 });

    try array.swap(5, 7);
    try expect(array.asSlice()).isSlice(usize, &.{ 10, 7, 20, 20, 3, 16, 15, 14 });

    array.reverse();
    try expect(array.asSlice()).isSlice(usize, &.{ 14, 15, 16, 3, 20, 20, 7, 10 });

    try array.addFirstAll(allocator, &.{ 22, 23, 24 });
    try expect(array.asSlice()).isSlice(usize, &.{ 22, 23, 24, 14, 15, 16, 3, 20, 20, 7, 10 });

    try array.addLastAll(allocator, &.{ 25, 26, 27 });
    try expect(array.asSlice()).isSlice(usize, &.{ 22, 23, 24, 14, 15, 16, 3, 20, 20, 7, 10, 25, 26, 27 });

    try array.removeAll(3, 10);
    try expect(array.asSlice()).isSlice(usize, &.{ 22, 23, 24, 27 });

    const slice = try array.copyToSlice(allocator);
    defer allocator.free(slice);
    try expect(slice).isSlice(usize, &.{ 22, 23, 24, 27 });
}

test "format" {
    const Array = StaticDynamicArray(u8, 10);
    const allocator = std.testing.allocator;

    var array = Array.init();
    defer array.deinit();

    try array.addLast(1);
    try array.addLast(2);
    try array.addLast(3);
    try array.addLast(4);
    try array.addLast(5);

    const format = try std.fmt.allocPrint(a, "{}", .{array});
    defer a.free(format);

    try lib.assert.expectEqualString("StaticDynamicArray(u8){ 1, 2, 3, 4, 5 }", format);
}
