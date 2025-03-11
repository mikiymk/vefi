const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const Array = lib.collection.DynamicArray;
const Self = @This();

values: Array(u8),
indexes: Array(usize),

pub fn init() @This() {
    return .{
        .values = &.{},
        .last_indexes = &.{},
    };
}

/// すべてのメモリを解放する。
pub fn deinit(self: *@This(), a: Allocator) void {
    self.values.deinit(a);
    self.indexes.deinit(a);
}

fn getRange(self: @This(), index: usize) struct { usize, usize } {
    const begin = if (index == 0) 0 else self.indexes.get(index - 1);
    const end = self.indexes.get(index);

    return .{ begin, end };
}

/// 配列の要素数を返す。
pub fn size(self: @This()) usize {
    return self.indexes.size();
}

/// 配列の`index`番目の要素を返す。
/// 配列の範囲外の場合、未定義動作を起こす。
pub fn get(self: @This(), index: usize) []u8 {
    const begin, const end = self.getRange(index);
    return self.values.asSlice()[begin..end];
}

/// 配列の`index`番目の要素の値を設定する。
/// 配列の範囲外の場合、未定義動作を起こす。
pub fn set(self: *@This(), a: Allocator, index: usize, value: []u8) void {
    const begin, const end = self.getRange(index);
    const old_length = end - begin;
    const new_length = value.len;

    if (old_length < new_length) {} else if (new_length < old_length) {}
    @memcpy(self.values.asSlice()[begin..][0..new_length], value);
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
