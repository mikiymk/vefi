const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const AllocatorError = lib.allocator.AllocatorError;
const assert = lib.assert.assert;

pub const DynamicArrayOptions = struct {
    extend_factor: usize = 2,
    max_length: ?usize = null,
};

/// 動的配列 (Dynamic Array)
pub fn DynamicArray(T: type, comptime options: DynamicArrayOptions) type {
    _ = options;

    return struct {
        values: []T,
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
            allocator.free(self.values);
        }

        pub fn assertBound(self: @This(), index: usize) bool {
            assert(index < self.size);
        }

        /// 配列の`index`番目の要素を返す。
        pub fn get(self: @This(), index: usize) T {
            self.assertBound(index);
            return self.values[index];
        }

        /// 配列の`index`番目の要素への参照を返す。
        pub fn getRef(self: @This(), index: usize) *T {
            self.assertBound(index);
            return @ptrCast(self.values.ptr + index);
        }

        pub fn set(self: *@This(), index: usize, value: T) void {
            self.assertBound(index);
            self.values[index] = value;
        }

        pub fn fill(self: *@This(), begin: usize, end: usize, value: T) void {
            self.assertBound(begin);
            assert(end <= self.size);
            @memset(self.values[begin..end], value);
        }

        pub fn swap(self: *@This(), left: usize, right: usize) void {
            self.assertBound(left);
            self.assertBound(right);

            const tmp = self.get(left);
            self.set(left, self.get(right));
            self.set(right, tmp);
        }

        pub fn reverse(self: @This()) usize {
            for (0..(self.size() / 2)) |i| {
                self.swap(i, self.size - 1);
            }
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        pub fn pushFront(self: *@This(), allocator: Allocator, item: T) AllocatorError!void {
            try self.insert(allocator, 0, item);
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        pub fn pushBack(self: *@This(), allocator: Allocator, item: T) AllocatorError!void {
            if (self.values.len <= self.size) {
                try self.extendSize(allocator);
            }

            self.values[self.size] = item;
            self.size += 1;
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn popFront(self: *@This()) ?T {
            return self.delete(0);
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn popBack(self: *@This()) ?T {
            if (self.size == 0) return null;
            self.size -= 1;
            return self.values[self.size];
        }

        /// 配列の`index`番目に新しい要素を追加する。
        pub fn insert(self: *@This(), allocator: Allocator, index: usize, item: T) AllocatorError!void {
            if (self.values.len <= self.size) {
                try self.extendSize(allocator);
            }

            self.size += 1;

            var value = item;
            for (self.values[index..self.size]) |*e| {
                const tmp = value;
                value = e.*;
                e.* = tmp;
            }
        }

        /// 配列の`index`番目の要素を削除する。
        pub fn delete(self: *@This(), index: usize) ?T {
            const value = self.get(index) orelse return null;

            self.size -= 1;
            for (self.values[index..self.size], self.values[(index + 1)..(self.size + 1)]) |*e, f| {
                e.* = f;
            }

            return value;
        }

        pub fn clone(self: @This(), allocator: Allocator) @This() {
            const new_array = init();
            new_array.size = self.size;
            new_array.values = self.copyToSlice(allocator);

            return new_array;
        }

        /// 配列をスライスとして取得する。
        pub fn asSlice(self: @This()) []const T {
            return self.values[0..self.size];
        }

        /// 配列を新しいスライスにコピーする。
        pub fn copyToSlice(self: @This(), allocator: Allocator) AllocatorError![]const T {
            var slice = try allocator.alloc(T, self.size);
            @memcpy(slice[0..self.size], self.values[0..self.size]);

            return slice;
        }

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) AllocatorError!void {
            self.values = try lib.collection.extendSize(allocator, self.values);
        }
    };
}

test DynamicArray {
    const allocator = std.testing.allocator;
    const DA = DynamicArray(u8);
    const eq = lib.assert.expectEqual;

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