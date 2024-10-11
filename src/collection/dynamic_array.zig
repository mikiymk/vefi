const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const AllocatorError = lib.allocator.AllocatorError;

/// 動的配列
pub fn DynamicArray(T: type) type {
    return struct {
        value: []T,
        size: usize,

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{
                .value = &[_]T{},
                .size = 0,
            };
        }

        /// すべてのメモリを解放する。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.value);
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        pub fn push(self: *@This(), allocator: Allocator, item: T) AllocatorError!void {
            if (self.value.len <= self.size) {
                try self.extendSize(allocator);
            }

            self.value[self.size] = item;
            self.size += 1;
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn pop(self: *@This()) ?T {
            if (self.size == 0) return null;
            self.size -= 1;
            return self.value[self.size];
        }

        /// 配列の`N`番目の要素を返す。
        /// `N`が配列の長さより大きい場合、nullを返す。
        pub fn get(self: @This(), index: usize) ?T {
            if (index >= self.size) return null;
            return self.value[index];
        }

        /// 配列の`N`番目の要素を返す。
        /// `N`が配列の長さより大きい場合、nullを返す。
        pub fn getRef(self: @This(), index: usize) ?*T {
            if (index >= self.size) return null;
            return @ptrCast(self.value.ptr + index);
        }

        /// 配列の`N`番目に新しい要素を追加する。
        pub fn insert(self: *@This(), allocator: Allocator, index: usize, item: T) AllocatorError!void {
            if (self.value.len <= self.size) {
                try self.extendSize(allocator);
            }

            self.size += 1;

            var value = item;
            for (self.value[index..self.size]) |*e| {
                const tmp = value;
                value = e.*;
                e.* = tmp;
            }
        }

        /// 配列の`N`番目の要素を削除する。
        pub fn delete(self: *@This(), index: usize) ?T {
            const value = self.get(index) orelse return null;

            self.size -= 1;
            for (self.value[index..self.size], self.value[(index + 1)..(self.size + 1)]) |*e, f| {
                e.* = f;
            }

            return value;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self.value[0..self.size];
        }

        /// 配列を新しいスライスにコピーする。
        pub fn copyToSlice(self: @This(), allocator: Allocator) AllocatorError![]const T {
            var slice = try allocator.alloc(T, self.size);
            @memcpy(slice[0..self.size], self.value[0..self.size]);

            return slice;
        }

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) AllocatorError!void {
            self.value = try lib.collection.extendSize(allocator, self.value);
        }
    };
}

test DynamicArray {
    const allocator = std.testing.allocator;
    const DA = DynamicArray(u8);
    const eq = lib.assert.expectEqual;

    var array = DA.init();
    defer array.deinit(allocator);

    try array.push(allocator, 5);
    try eq(array.asSlice(), &.{5});

    try array.push(allocator, 6);
    try array.push(allocator, 7);
    try eq(array.asSlice(), &.{ 5, 6, 7 });

    try eq(array.pop(), 7);
    try eq(array.pop(), 6);
    try eq(array.pop(), 5);
    try eq(array.pop(), null);
    try eq(array.asSlice(), &.{});

    try array.push(allocator, 5);
    try array.push(allocator, 6);
    try array.push(allocator, 7);
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
