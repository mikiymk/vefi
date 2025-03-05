const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn size(head: anytype) usize {
    var node = head;
    var count: usize = 0;

    while (node) |n| : (node = n.next) count += 1;
    return count;
}

pub fn sizeSentinel(head: anytype, sentinel: @TypeOf(head)) usize {
    var node = head;
    var count: usize = 0;

    while (node != sentinel) : (node = node.next) count += 1;
    return count;
}

pub fn clear(a: Allocator, head: anytype) void {
    var node = head;
    while (node) |n| {
        const next = n.next;
        n.deinit(a);
        node = next;
    }
}

pub fn clearSentinel(a: Allocator, head: anytype, sentinel: @TypeOf(head)) void {
    var node = head;

    while (node != sentinel) {
        const next = node.next;
        node.deinit(a);
        node = next;
    }
}

fn Option(T: type) type {
    return if (@typeInfo(T) == .Optional) T else ?T;
}

pub fn getNode(head: anytype, index: usize) Option(@TypeOf(head)) {
    var node = head;
    var count = index;

    return while (node) |n| : (node = n.next) {
        if (count == 0) break n;
        count -= 1;
    } else null;
}

pub fn getNodeSentinel(head: anytype, sentinel: @TypeOf(head), index: usize) @TypeOf(head) {
    var node = head;
    var count = index;

    while (node != sentinel and count != 0) : (node = node.next) {
        count -= 1;
    }
    return node;
}

pub fn format(w: anytype, type_name: []const u8, head: anytype) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    var node = head;
    var first = true;
    while (node) |n| : (node = n.next) {
        const sep = if (first) b: {
            first = false;
            break :b " ";
        } else ", ";

        try writer.print("{s}{}", .{ sep, n });
    }
    try writer.print(" }}", .{});
}

pub fn formatSentinel(w: anytype, type_name: []const u8, head: anytype, sentinel: @TypeOf(head)) !void {
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
