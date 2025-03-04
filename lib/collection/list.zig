const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn formatList(w: anytype, type_name: []const u8, node: anytype) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    var n = node;
    var first = true;
    while (n) |nn| : (n = nn.next) {
        if (first) {
            try writer.print(" ", .{});
            first = false;
        } else {
            try writer.print(", ", .{});
        }

        try writer.print("{}", .{nn});
    }
    try writer.print(" }}", .{});
}

pub fn formatListSentinel(w: anytype, type_name: []const u8, node: anytype, sentinel: @TypeOf(node)) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    var n = node;
    var first = true;
    while (n != sentinel) : (n = n.next) {
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
