const std = @import("std");
const lib = @import("../../root.zig");

/// # 静的配列 (Static Array)
/// - サイズがコンパイル時に決まる。
pub fn StaticArray(T: type, array_size: usize) type {
    return struct {
        pub const Item = T;
        pub const Range = lib.collection.Range;
        pub const IndexError = error{OutOfBounds};

        values: [array_size]T,

        /// 値を初期化せずに配列を作成する。
        pub fn init() @This() {
            return .{ .values = undefined };
        }

        /// インデックスが配列の範囲内かどうか判定する。
        pub fn isInBound(self: @This(), index: usize) bool {
            const size_ = self.size();

            return 0 <= index and index < size_;
        }

        /// 配列の要素数を返す。
        pub fn size(self: @This()) usize {
            return self.values.len;
        }

        /// 配列の`index`番目の要素を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?T {
            if (!self.isInBound(index)) return null;

            return self.values[index];
        }

        /// 配列の`index`番目の要素への参照を返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn getRef(self: *@This(), index: usize) ?*T {
            if (!self.isInBound(index)) return null;

            return &self.values[index];
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            if (!self.isInBound(index)) return error.OutOfBounds;

            self.values[index] = value;
        }

        /// 繰り返しオブジェクトを作成する
        pub iterator(self: *@This()) Iterator {
            return .{ .ref = self };
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

/// 配列の繰り返しオブジェクト
pub fn Iterator(Array: type) type {
    return struct {
    pub const Item = Array.Item;
    index: usize = 0,
    array: *Array,

    /// あれば次の値を返す
    pub fn next(self: *@This()) ?Item {
        if (self.array.isInBound(self.index)) {
            defer self.index += 1;
            return self.array.values[self.index];
        }
        return null;
    }
};
}

test StaticArray {
    const Array = StaticArray(usize, 5);
    const eq = lib.assert.expectEqualStruct;
    const eqSlice = lib.assert.expectEqualSlice;

    var array = Array.init(.{ 1, 2, 3, 4, 5 });
    try eq(array.values, .{ 1, 2, 3, 4, 5 });

    try eq(array.size(), 5);
    try eq(array.get(0), 1);
    try eq(array.get(5), null);
    try eq(array.getRef(0).?.*, 1);
    try eq(array.getRef(5), null);
    try eqSlice(usize, array.slice(.{ 1, 3 }).?, &.{ 2, 3 });

    const ptr = array.getRef(0).?;
    ptr.* = 6;
    try eq(array.values, .{ 6, 2, 3, 4, 5 });

    try array.set(4, 7);
    try eq(array.values, .{ 6, 2, 3, 4, 7 });

    try array.setFill(.{ 1, 3 }, 8);
    try eq(array.values, .{ 6, 8, 8, 4, 7 });

    try array.setAll(1, &.{ 9, 10, 11 });
    try eq(array.values, .{ 6, 9, 10, 11, 7 });

    try array.swap(2, 4);
    try eq(array.values, .{ 6, 9, 7, 11, 10 });

    array.reverse();
    try eq(array.values, .{ 10, 11, 7, 9, 6 });
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
