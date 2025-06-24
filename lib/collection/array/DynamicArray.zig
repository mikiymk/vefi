const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;
const Range = lib.collection.Range;

/// # 動的配列 (Dynamic Array)
/// - アロケーターを使ってメモリーを確保する
/// - 追加のたびに再アロケーションをしない
pub fn DynamicArray(T: type) type {
    return struct {
        pub const Item = T;

        pub const IndexError = error{OutOfBounds};
        pub const AllocError = Allocator.Error;
        pub const AllocIndexError = AllocError || IndexError;

        values: []T,
        length: usize,

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{ .values = undefined, .length = 0 };
        }

        /// すべてのメモリを解放する。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.values);
            self.* = undefined;
        }

        /// インデックスが配列の範囲内かどうか判定する。
        pub fn isInBound(self: @This(), index: usize) bool {
            return index < self.size();
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

        /// 配列の`index`番目の要素を参照で返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?*T {
            if (!self.isInBound(index)) {
                return null;
            }

            return &self.values[index];
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            if (!self.isInBound(index)) {
                return error.OutOfBounds;
            }

            self.values[index] = value;
        }

        fn copyInArray(slice: anytype, src: usize, dst: usize, length: usize) IndexError!void {
            const src_end = src + length;
            const dst_end = dst + length;

            if (src == dst or length == 0) return; // 何もしない場合
            if (!self.isInBoundRange(.{ src, src_end })) return error.OutOfBounds;
            if (!self.isInBoundRange(.{ dst, dst_end })) return error.OutOfBounds;

            const dst_slice = slice[dst..dst_end];
            const src_slice = slice[src..src_end];

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

        /// 配列の`index`番目に新しい要素を追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn add(self: *@This(), allocator: Allocator, index: usize, item: T) AllocIndexError!void {
            if (self.values.len <= self.length) {
                try self.extendSize(allocator);
            }

            self.length += 1;
            try self.copyInArray(index, index + 1, self.size() - index - 1);
            self.values[index] = item;
        }

        /// 配列の`index`番目の要素を削除し、値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn remove(self: *@This(), index: usize) ?T {
            const value = (self.get(index) orelse return null).*;

            try self.copyInArray(index + 1, index, self.size() - index - 1);
            self.length -= 1;

            return value;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self.values[0..self.length];
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
            if (allocate_size < self.values.len)
                return;

            self.values = try allocator.realloc(self.values, allocate_size);
        }

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) Allocator.Error!void {
            const extend_factor = 2;
            const initial_length = 8;

            const length = self.values.len;
            const new_length: usize = if (length == 0) initial_length else length * extend_factor;

            self.values = try allocator.realloc(self.values, new_length);
        }

        pub fn iterator(self: *@This()) Iterator(@This()) {
            return .{ .array = self };
        }

        // 文字列に変換する
        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("DynamicArray({s}){{", .{@typeName(T)});

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
    const Array = DynamicArray(usize);
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
    const Array = DynamicArray(u8);
    const a = std.testing.allocator;

    var array = Array.init();
    defer array.deinit(a);

    try array.addLast(a, 1);
    try array.addLast(a, 2);
    try array.addLast(a, 3);
    try array.addLast(a, 4);
    try array.addLast(a, 5);

    const format = try std.fmt.allocPrint(a, "{}", .{array});
    defer a.free(format);

    try lib.assert.expectEqualString("DynamicArray(u8){ 1, 2, 3, 4, 5 }", format);
}
