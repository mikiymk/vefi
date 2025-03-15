const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const Array = lib.collection.array.DynamicArray;
pub const Range = lib.collection.Range;

const StringArray = @This();
pub const Item = []const u8;

pub const IndexError = error{OutOfBounds};
pub const AllocError = Allocator.Error;
pub const AllocIndexError = AllocError || IndexError;

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

pub fn clear(self: *@This(), a: Allocator) void {
    self.values.clear(a);
    self.indexes.clear(a);
}

/// 配列の`index`番目の要素を返す。
pub fn get(self: @This(), index: usize) ?[]const u8 {
    const begin, const end = self.getRange(index) orelse return null;
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

/// 配列の`index`番目に新しい要素を追加する。
pub fn add(self: *@This(), allocator: Allocator, index: usize, item: []const u8) AllocIndexError!void {
    const prev_index = if (index == 0) 0 else self.indexes.get(index - 1) orelse return error.OutOfBounds;
    try self.indexes.add(allocator, index, prev_index);
    try self.values.addAll(allocator, prev_index, item);
    for (self.indexes.values[index..self.indexes.size()]) |*i| {
        i.* += item.len;
    }
}

/// 値を配列の最も後ろに追加する。
/// 配列の長さが足りないときは拡張した長さの配列を再確保する。
pub fn addFirst(self: *@This(), allocator: Allocator, item: []const u8) AllocError!void {
    self.add(allocator, 0, item) catch |err| switch (err) {
        error.OutOfBounds => unreachable,
        else => |e| return e,
    };
}

/// 値を配列の最も後ろに追加する。
/// 配列の長さが足りないときは拡張した長さの配列を再確保する。
pub fn addLast(self: *@This(), allocator: Allocator, item: []const u8) Allocator.Error!void {
    try self.values.addLastAll(allocator, item);
    try self.indexes.addLast(allocator, self.values.size());
}

/// 配列の`index`番目の要素を削除する。
pub fn remove(self: *@This(), index: usize) IndexError!void {
    const begin, const end = self.getRange(index) orelse return error.OutOfBounds;
    const length = end - begin;
    _ = self.indexes.remove(index) orelse unreachable;
    self.values.removeAll(begin, length) catch unreachable;
    for (self.indexes.values[index..self.indexes.size()]) |*i| {
        i.* -= length;
    }
}

/// 配列の最も後ろの要素を削除し、その値を返す。
/// 配列が要素を持たない場合、配列を変化させずにnullを返す。
pub fn removeFirst(self: *@This()) IndexError!void {
    return self.remove(0);
}

/// 配列の最も後ろの要素を削除し、その値を返す。
/// 配列が要素を持たない場合、配列を変化させずにnullを返す。
pub fn removeLast(self: *@This()) IndexError!void {
    _ = self.indexes.removeLast() orelse return error.OutOfBounds;
    const index = self.indexes.size();
    const begin = if (index == 0) 0 else self.indexes.get(index - 1) orelse unreachable;
    self.values.removeAll(begin, self.values.size() - begin) catch unreachable;
}

pub fn copyToSlice(self: @This(), allocator: Allocator) AllocError![]const []const u8 {
    var array = Array([]const u8).init();

    var begin: usize = 0;
    var end: usize = 0;
    for (self.indexes.asSlice()) |index| {
        begin = end;
        end = index;
        const str = self.values.values[begin..end];
        try array.pushBack(allocator, str);
    }

    const slice = try array.copyToSlice(allocator);
    return slice;
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

        const str = self.values.values[begin..end];
        try writer.print("\"{s}\"", .{str});
    }

    try writer.print(" }}", .{});
}

test StringArray {
    const allocator = std.testing.allocator;
    const expect = lib.testing.expect;

    var array = StringArray.init();
    defer array.deinit(allocator);

    try expect(array.values.asSlice()).isString("");
    try expect(array.indexes.asSlice()).isSlice(usize, &.{});

    try array.addLast(allocator, "hello");
    try expect(array.size()).is(1);
    try expect(array.get(0)).opt().isString("hello");
    try expect(array.get(1)).isNull();

    try array.addFirst(allocator, "world");
    try expect(array.size()).is(2);
    try expect(array.get(0)).opt().isString("world");
    try expect(array.get(1)).opt().isString("hello");
    try expect(array.get(2)).isNull();

    try array.add(allocator, 1, "zig");
    try expect(array.size()).is(3);
    try expect(array.get(0)).opt().isString("world");
    try expect(array.get(1)).opt().isString("zig");
    try expect(array.get(2)).opt().isString("hello");
    try expect(array.get(3)).isNull();

    try array.remove(1);
    try expect(array.size()).is(2);
    try expect(array.get(0)).opt().isString("world");
    try expect(array.get(1)).opt().isString("hello");
    try expect(array.get(2)).isNull();

    try array.removeFirst();
    try expect(array.size()).is(1);
    try expect(array.get(0)).opt().isString("hello");
    try expect(array.get(1)).isNull();

    try array.removeLast();
    try expect(array.size()).is(0);
    try expect(array.get(1)).isNull();

    try array.add(allocator, 0, "hello");
    try array.remove(0);
    try array.addFirst(allocator, "hello");
    try array.removeFirst();
    try array.addLast(allocator, "hello");
    try array.removeLast();
}

test "format" {
    const Array_ = StringArray;
    const a = std.testing.allocator;

    var array = Array_.init();
    defer array.deinit(a);

    try array.addLast(a, "hello");
    try array.addLast(a, "world");
    try array.addLast(a, "zig");
    try array.addLast(a, "array");
    try array.addLast(a, "list");

    const formatted = try std.fmt.allocPrint(a, "{}", .{array});
    defer a.free(formatted);

    try lib.assert.expectEqualString("StringArray{ \"hello\", \"world\", \"zig\", \"array\", \"list\" }", formatted);
}
