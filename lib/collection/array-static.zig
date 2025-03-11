const std = @import("std");
const lib = @import("../root.zig");

const assert = lib.assert.assert;

/// 静的配列 (Static Array)
pub fn StaticArray(T: type, array_size: usize) type {
    return struct {
        pub const Range = lib.collection.Range;
        pub const IndexError = error{OutOfBounds};

        values: [array_size]T,

        /// 配列を初期化する。
        /// 与えた配列の値で初期化する。
        pub fn init(initial_array: [array_size]T) @This() {
            return .{ .values = initial_array };
        }

        /// 配列を初期化する。
        /// 配列をすべて同じ値に初期化する。
        pub fn initWithValue(initial_value: T) @This() {
            return init(.{initial_value} ** array_size);
        }

        /// 配列を解放する。
        pub fn deinit(self: *@This()) void {
            self.* = undefined;
        }

        /// インデックスが配列の範囲内かどうか判定する。
        pub fn isInBoundIndex(self: @This(), index: usize) bool {
            return 0 <= index and index < self.size();
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
            return self.values.len;
        }

        /// 配列の`index`番目の要素を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?T {
            if (!self.isInBoundIndex(index)) return null;

            return self.values[index];
        }

        /// 配列の`index`番目の要素への参照を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn getRef(self: *@This(), index: usize) ?*T {
            if (!self.isInBoundIndex(index)) return null;

            return &self.values[index];
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
            if (!self.isInBoundIndex(index)) return error.OutOfBounds;

            self.values[index] = value;
        }

        /// 配列の`index`番目から先を新しい値のスライスで更新する。
        /// `index`からスライスの範囲が配列の範囲外の場合、エラーを返す。
        pub fn setAll(self: *@This(), index: usize, values: []const T) IndexError!void {
            if (!self.isInBoundIndex(index)) return error.OutOfBounds;

            @memcpy(self.values[index..][0..values.len], values);
        }

        /// 配列の`begin`番目(含む)から`end`番目(含まない)の要素の値をまとめて設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn setFill(self: *@This(), range: Range, value: T) IndexError!void {
            if (!self.isInBoundRange(range)) return error.OutOfBounds;
            const begin, const end = range;

            @memset(self.values[begin..end], value);
        }

        /// 配列の`left`番目と`right`番目の要素の値を交換する。
        /// `left`か`right`が配列の範囲外の場合、エラーを返す。
        pub fn swap(self: *@This(), left: usize, right: usize) IndexError!void {
            if (!self.isInBoundIndex(left)) return error.OutOfBounds;
            if (!self.isInBoundIndex(right)) return error.OutOfBounds;

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

        /// 配列を文字列にする。
        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
            const writer = lib.io.writer(w);
            try writer.print("StaticArray({s}){{", .{@typeName(T)});

            var first = true;
            for (self.values) |value| {
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

test StaticArray {
    const Array = StaticArray(usize, 5);
    const equals = lib.assert.expectEqualStruct;

    var array = Array.init(.{ 1, 2, 3, 4, 5 });
    try equals(array.values, .{ 1, 2, 3, 4, 5 });

    try array.set(0, 6);
    try equals(array.values, .{ 6, 2, 3, 4, 5 });
    try equals(array.get(0), 6);

    const ptr = array.getRef(4).?;
    ptr.* = 7;
    try equals(array.values, .{ 6, 2, 3, 4, 7 });

    try array.setFill(.{ 1, 3 }, 8);
    try equals(array.values, .{ 6, 8, 8, 4, 7 });

    try array.swap(2, 4);
    try equals(array.values, .{ 6, 8, 7, 4, 8 });

    array.reverse();
    try equals(array.values, .{ 8, 4, 7, 8, 6 });
}

test "format" {
    const Array = StaticArray(u8, 5);
    const a = std.testing.allocator;

    var array = Array.init(.{ 1, 2, 3, 4, 5 });
    defer array.deinit();

    const format = try std.fmt.allocPrint(a, "{}", .{array});
    defer a.free(format);

    try lib.assert.expectEqualString("StaticArray(u8){ 1, 2, 3, 4, 5 }", format);
}
