const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn size(head: anytype, sentinel: @TypeOf(head)) usize {
    var node = head;
    var count: usize = 0;

    while (node != sentinel) : (node = node.next) count += 1;
    return count;
}

pub fn clear(a: Allocator, head: anytype, sentinel: @TypeOf(head)) void {
    var node = head;

    while (node != sentinel) {
        const next = node.next;
        node.deinit(a);
        node = next;
    }
}

pub fn getNode(head: anytype, sentinel: @TypeOf(head), index: usize) @TypeOf(head) {
    var node = head;
    var count = index;

    while (node != sentinel and count != 0) : (node = node.next) {
        count -= 1;
    }
    return node;
}

pub fn getNodeFromLast(tail: anytype, sentinel: @TypeOf(head), index: usize) @TypeOf(head) {
    var node = tail;
    var count = index;

    while (node != sentinel and count != 0) : (node = node.prev) {
        count -= 1;
    }
    return node;
}

pub fn getLastNode(head: anytype, sentinel: @TypeOf(head)) @TypeOf(head) {
    var prev = sentinel;
    var node = head;

    while (node != sentinel) : (node = node.next) {
        prev = node;
    }

    return prev;
}

pub fn getLastNode2(head: anytype, sentinel: @TypeOf(head)) @TypeOf(head) {
    var prev_prev = sentinel;
    var prev = sentinel;
    var node = head;

    while (node != sentinel) : (node = node.next) {
        prev_prev = prev;
        prev = node;
    }

    return prev_prev;
}

pub fn format(w: anytype, type_name: []const u8, head: anytype, sentinel: @TypeOf(head)) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    var node = head;
    var first = true;
    while (node != sentinel) : (node = node.next) {
        const sep = if (first) b: {
            first = false;
            break :b " ";
        } else ", ";

        try writer.print("{s}{}", .{ sep, node });
    }
    try writer.print(" }}", .{});
}
