const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const Array = lib.collection.DynamicArray;
const StringArray = @This();

pub const Range = struct { usize, usize };

values: Array(u8),
indexes: Array(usize),

pub fn init() @This() {
    return .{
        .values = Array(u8).init(),
        .indexes = Array(usize).init(),
    };
}

/// すべてのメモリを解放する。
pub fn deinit(self: *@This(), a: Allocator) void {
    self.values.deinit(a);
    self.indexes.deinit(a);
}

fn getRange(self: @This(), index: usize) ?Range {
    const end = self.indexes.get(index) orelse return null;
    const begin = if (index == 0) 0 else self.indexes.get(index - 1).?;

    return .{ begin, end };
}

/// 配列の要素数を返す。
pub fn size(self: @This()) usize {
    return self.indexes.size();
}

/// 配列の`index`番目の要素を返す。
pub fn get(self: @This(), index: usize) ?[]u8 {
    const begin, const end = self.getRange(index);
    return self.values.asSlice()[begin..end];
}

/// 配列の`index`番目の要素の値を設定する。
/// 配列の範囲外の場合、未定義動作を起こす。
pub fn set(self: *@This(), a: Allocator, index: usize, value: []u8) void {
    const begin, const end = self.getRange(index);
    const old_length = end - begin;
    const new_length = value.len;

    if (old_length < new_length) {
        const diff = new_length - old_length;
        self.values.reserve(a, self.values.size() + diff);
    } else if (new_length < old_length) {}
    @memcpy(self.values.asSlice()[begin..][0..new_length], value);
}

/// 値を配列の最も後ろに追加する。
/// 配列の長さが足りないときは拡張した長さの配列を再確保する。
pub fn pushFront(self: *@This(), allocator: Allocator, item: []u8) Allocator.Error!void {
    try self.insert(allocator, 0, item);
}

/// 値を配列の最も後ろに追加する。
/// 配列の長さが足りないときは拡張した長さの配列を再確保する。
pub fn pushBack(self: *@This(), allocator: Allocator, item: []const u8) Allocator.Error!void {
    const length = item.len;
    const begin = self.values.size();
    const end = begin + length;
    try self.values.reserve(allocator, end);
    @memcpy(self.values._values[begin..end], item);
    self.values._size += length;
    try self.indexes.pushBack(allocator, end);
}

/// 配列の最も後ろの要素を削除し、その値を返す。
/// 配列が要素を持たない場合、配列を変化させずにnullを返す。
pub fn popFront(self: *@This()) ?[]u8 {
    return self.delete(0);
}

/// 配列の最も後ろの要素を削除し、その値を返す。
/// 配列が要素を持たない場合、配列を変化させずにnullを返す。
pub fn popBack(self: *@This()) ?[]u8 {
    if (self._size == 0) return null;
    self._size -= 1;
    return self._values[self._size];
}

/// 配列の`index`番目に新しい要素を追加する。
pub fn insert(self: *@This(), allocator: Allocator, index: usize, item: []u8) Allocator.Error!void {
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
pub fn delete(self: *@This(), index: usize) ?[]u8 {
    const value = self.get(index);

    self._size -= 1;
    for (self._values[index..self._size], self._values[(index + 1)..(self._size + 1)]) |*e, f| {
        e.* = f;
    }

    return value;
}

pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
    const writer = lib.io.writer(w);
    try writer.print("StringArray{{", .{});

    var first = true;
    var begin: usize = 0;
    var end: usize = 0;
    for (self.indexes.asSlice()) |index| {
        begin = end;
        end = index;
        if (first) {
            try writer.print(" ", .{});
            first = false;
        } else {
            try writer.print(", ", .{});
        }

        const str = self.values._values[begin..end];
        try writer.print("\"{s}\"", .{str});
    }

    try writer.print(" }}", .{});
}

test "format" {
    const Array_ = StringArray;
    const a = std.testing.allocator;

    var array = Array_.init();
    defer array.deinit(a);

    try array.pushBack(a, "hello");
    try array.pushBack(a, "world");
    try array.pushBack(a, "zig");
    try array.pushBack(a, "array");
    try array.pushBack(a, "list");

    const formatted = try std.fmt.allocPrint(a, "{}", .{array});
    defer a.free(formatted);

    try lib.assert.expectEqualString("StringArray{ \"hello\", \"world\", \"zig\", \"array\", \"list\" }", formatted);
}
