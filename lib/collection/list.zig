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

pub fn format(w: anytype, type_name: []const u8, head: anytype) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    var node = head;
    var first = true;
    while (node) |n| : (node = n.next) {
        if (first) {
            try writer.print(" ", .{});
            first = false;
        } else {
            try writer.print(", ", .{});
        }

        try writer.print("{}", .{n});
    }
    try writer.print(" }}", .{});
}

pub fn formatSentinel(w: anytype, type_name: []const u8, head: anytype, sentinel: @TypeOf(head)) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    var node = head;
    var first = true;
    while (node != sentinel) : (node = node.next) {
        if (first) {
            try writer.print(" ", .{});
            first = false;
        } else {
            try writer.print(", ", .{});
        }

        try writer.print("{}", .{node});
    }
    try writer.print(" }}", .{});
}
