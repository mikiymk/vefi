const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const expectEq = lib.assert.expectEqualP;

pub fn testList(List: type, list: *List, a: Allocator) !void {
    // list == .{}
    try expectEq(list.size(), 0);
    try expectEq(list.getFirst(), null);
    try expectEq(list.getLast(), null);

    try list.addFirst(a, 4);
    try list.addFirst(a, 3);
    try list.addLast(a, 7);
    try list.addLast(a, 8);
    try list.add(a, 2, 5);
    try list.add(a, 3, 6);

    // list == .{3, 4, 5, 6, 7, 8}
    try expectEq(list.size(), 6);
    try expectEq(list.getFirst(), 3);
    try expectEq(list.getLast(), 8);
    try expectEq(list.get(0), 3);
    try expectEq(list.get(1), 4);
    try expectEq(list.get(2), 5);
    try expectEq(list.get(3), 6);
    try expectEq(list.get(4), 7);
    try expectEq(list.get(5), 8);

    try list.removeFirst(a);
    try list.removeLast(a);
    try list.remove(a, 1);

    // list == .{4, 6, 7}
    try expectEq(list.size(), 3);
    try expectEq(list.get(1), 6);
}

pub fn testGetFromLast(List: type, list: *List, a: Allocator) !void {
    list.clear(a);
    try list.addLast(a, 1);
    try list.addLast(a, 2);
    try list.addLast(a, 3);
    try list.addLast(a, 4);
    try list.addLast(a, 5);

    // .{ 1, 2, 3, 4, 5 }
    try expectEq(list.getFromLast(0), 5);
    try expectEq(list.getFromLast(4), 1);
}

pub fn testRemoveToZero(List: type, list: *List, a: Allocator) !void {
    list.clear(a);

    try list.addFirst(a, 1);
    try list.removeFirst(a);
    try expectEq(list.size(), 0);

    try list.addLast(a, 1);
    try list.removeLast(a);
    try expectEq(list.size(), 0);

    try list.add(a, 0, 1);
    try list.remove(a, 0);
    try expectEq(list.size(), 0);
}

pub fn testIndexError(List: type, list: *List, a: Allocator) !void {
    const expectError = lib.assert.expectError;
    list.clear(a);

    try expectError(list.add(a, 1, 10), error.OutOfBounds);
    try expectError(list.remove(a, 0), error.OutOfBounds);
    try expectError(list.remove(a, 2), error.OutOfBounds);
    try expectError(list.removeFirst(a), error.OutOfBounds);
    try expectError(list.removeLast(a), error.OutOfBounds);
}
