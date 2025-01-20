const std = @import("std");
const lib = @import("../root.zig");

const Allocator = lib.allocator.Allocator;

// スタックの関数
// pop push
// peek size
// isEmpty clear
// iterator toSlice

// スタックの種類
// 動的配列・線形リスト

/// データを先入れ後出し(FILO)で保持するコレクションです。
pub fn Stack(T: type) type {
    return struct {
        pub const Value = T;

        value: []Value,
        size: usize,

        /// 空のスタックを作成します。
        pub fn init() @This() {
            return .{
                .value = &[_]T{},
                .size = 0,
            };
        }

        /// メモリを破棄し、スタックを終了します。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.value);
        }

        fn isFull(self: @This()) bool {
            return self.value.len <= self.size;
        }

        /// スタックの要素数を数えます。
        pub fn count(self: @This()) usize {
            return self.size;
        }

        /// スタックの先頭に要素を追加します。
        pub fn push(self: *@This(), allocator: Allocator, item: Value) Allocator.Error!void {
            if (self.isFull()) {
                try self.extendSize(allocator);
            }

            self.value[self.size] = item;
            self.size += 1;
        }

        /// スタックの先頭から要素を取り出します。
        pub fn pop(self: *@This()) ?Value {
            if (self.size == 0) {
                return null;
            }

            self.size -= 1;
            return self.value[self.size];
        }

        /// スタックの先頭の要素を取得します。
        pub fn peek(self: @This()) ?Value {
            if (self.size == 0) {
                return null;
            } else {
                return self.value[self.size - 1];
            }
        }

        const OuterThis = @This();
        pub const Iterator = struct {
            ref: *OuterThis,

            pub fn next(self: *@This()) ?Value {
                return self.ref.pop();
            }
        };

        /// スタックの要素を順番に取り出すイテレータを作成します。
        pub fn iterator(self: *@This()) Iterator {
            return .{
                .ref = self,
            };
        }

        fn extendSize(self: *@This(), allocator: Allocator) Allocator.Error!void {
            self.value = try lib.collection.extendSize(allocator, self.value);
        }
    };
}

test Stack {
    const S = Stack(usize);
    const a = std.testing.allocator;

    var s = S.init();
    defer s.deinit(a);

    try s.push(a, 3);
    try s.push(a, 4);
    try s.push(a, 5);

    try lib.assert.expectEqual(s.count(), 3);
    try lib.assert.expectEqual(s.pop(), 5);

    try s.push(a, 6);

    try lib.assert.expectEqual(s.count(), 3);
    try lib.assert.expectEqual(s.peek(), 6);
    try lib.assert.expectEqual(s.pop(), 6);
    try lib.assert.expectEqual(s.pop(), 4);
    try lib.assert.expectEqual(s.pop(), 3);
    try lib.assert.expectEqual(s.pop(), null);

    try s.push(a, 3);
    try s.push(a, 4);
    try s.push(a, 5);

    var iter = s.iterator();

    try lib.assert.expectEqual(iter.next(), 5);
    try lib.assert.expectEqual(iter.next(), 4);
    try lib.assert.expectEqual(iter.next(), 3);
    try lib.assert.expectEqual(iter.next(), null);

    try lib.assert.expectEqual(s.pop(), null);
}
