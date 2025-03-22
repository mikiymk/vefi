const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;
const assert = lib.assert.assert;

pub fn size(head: anytype) usize {
    var node = head;
    var count: usize = 0;

    while (node) |n| : (node = n.next) count += 1;
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

fn Option(T: type) type {
    return if (@typeInfo(T) == .optional) T else ?T;
}

pub fn getNode(head: anytype, index: usize) Option(@TypeOf(head)) {
    var node = head;
    var count = index;

    return while (node) |n| : (node = n.next) {
        if (count == 0) break n;
        count -= 1;
    } else null;
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
