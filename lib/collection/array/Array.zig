const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const assert = lib.assert.assert;
const Range = lib.collection.Range;
const copyInSlice = lib.collection.copyInSlice;

/// # 動的配列 (Dynamic Array)
/// - アロケーターを使ってメモリーを確保する
/// - 追加のたびに再アロケーションをしない
pub fn Array(T: type) type {
    return struct {
        pub const Item = T;

        pub const IndexError = error{OutOfBounds};
        pub const AllocIndexError = Allocator.Error || IndexError;

        items: []T,
        length: usize,

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{ .items = &.{}, .length = 0 };
        }

        /// すべてのメモリを解放する。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.items);
            self.* = undefined;
        }

        /// 配列の要素数を返す。
        pub fn size(self: @This()) usize {
            return self.length;
        }

        /// 配列の要素を全てなくす。
        pub fn clear(self: *@This()) void {
            self.length = 0;
        }

        fn isInBound(self: @This(), index: usize) bool {
            return index < self.length;
        }

        /// 配列の`index`番目の要素を参照で返す。
        /// 配列の範囲外の場合、`null`を返す。
        pub fn get(self: @This(), index: usize) ?*T {
            if (!self.isInBound(index)) {
                return null;
            }

            return &self.items[index];
        }

        /// 配列の`index`番目の要素の値を設定する。
        /// `index`が配列の範囲外の場合、エラーを返す。
        pub fn set(self: *@This(), index: usize, value: T) IndexError!void {
            if (!self.isInBound(index)) {
                return error.OutOfBounds;
            }

            self.items[index] = value;
        }

        /// 配列の`index`番目に新しい要素を追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        /// 再確保ができない場合はエラーを返す。
        pub fn add(self: *@This(), allocator: Allocator, index: usize, item: T) AllocIndexError!void {
            if (self.length < index) {
                return error.OutOfBounds;
            }
            if (self.items.len <= self.length) {
                try self.extendSize(allocator);
            }

            self.length += 1;
            copyInSlice(self.items, index, index + 1, self.size() - index - 1);
            self.items[index] = item;
        }

        /// 配列の`index`番目の要素を削除し、値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn remove(self: *@This(), index: usize) ?T {
            const value = (self.get(index) orelse return null).*;

            copyInSlice(self.items, index + 1, index, self.size() - index - 1);
            self.length -= 1;

            return value;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self.items[0..self.length];
        }

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) Allocator.Error!void {
            const extend_factor = 2;
            const initial_length = 8;

            const length = self.items.len;
            const new_length: usize = if (length == 0) initial_length else length * extend_factor;

            self.items = try allocator.realloc(self.items, new_length);
        }

        fn Iterator(U: type) type {
            _ = U;
            return void;
        }

        pub fn iterator(self: *@This()) Iterator(@This()) {
            return .{ .array = self };
        }

        /// 文字列に変換する
        pub fn format(self: @This(), writer: *Writer) Writer.Error!void {
            try writer.writeAll("Array(" ++ @typeName(T) ++ "){");
            for (self.items[0..self.length], 0..) |value, i| {
                try writer.print("{s}{}", .{ if (i == 0) " " else ", ", value });
            }
            try writer.writeAll(" }");
        }
    };
}

test Array {
    const A = Array(usize);
    const a = std.testing.allocator;
    const expect = lib.testing.expect;

    std.log.debug("Array test", .{});

    var array = A.init();
    defer array.deinit(a);

    try expect(array.asSlice()).isSlice(usize, &.{});
    try expect(array.size()).is(0);
    try expect(array.get(0)).isNull();

    try array.add(a, 0, 1);
    try array.add(a, 1, 2);
    try array.add(a, 2, 3);
    try expect(array.asSlice()).isSlice(usize, &.{ 1, 2, 3 });
    try expect(array.size()).is(3);
    try expect(array.get(0)).opt().ptr().is(1);

    try expect(array.remove(1)).is(2);
    try expect(array.asSlice()).isSlice(usize, &.{ 1, 3 });

    try array.add(a, 0, 4);
    try array.add(a, 1, 5);
    try expect(array.asSlice()).isSlice(usize, &.{ 4, 5, 1, 3 });

    try array.set(2, 6);
    try expect(array.set(5, 7)).isError(error.OutOfBounds);
    try expect(array.asSlice()).isSlice(usize, &.{ 4, 5, 6, 3 });
}

test "format" {
    const A = Array(u8);
    const a = std.testing.allocator;

    var array = A.init();
    defer array.deinit(a);

    try array.add(a, 0, 1);
    try array.add(a, 1, 2);
    try array.add(a, 2, 3);
    try array.add(a, 3, 4);
    try array.add(a, 4, 5);

    const format = try std.fmt.allocPrint(a, "{f}", .{array});
    defer a.free(format);

    try lib.assert.expectEqualString("Array(u8){ 1, 2, 3, 4, 5 }", format);
}
