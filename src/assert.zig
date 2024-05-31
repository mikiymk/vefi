const std = @import("std");
const lib = @import("./lib.zig");

pub fn assert(ok: bool) void {
    if (!ok) {
        unreachable;
    }
}

pub fn assertStatic(comptime ok: bool) void {
    if (!ok) {
        @compileError("assertion failed");
    }
}

pub fn expect(ok: bool) error{AssertionFailed}!void {
    if (!ok) {
        return error.AssertionFailed;
    }
}

pub fn expectEqual(left: anytype, right: @TypeOf(left)) error{AssertionFailed}!void {
    if (!lib.common.equal(left, right)) {
        std.debug.print("left: {any} != right: {any}\n", .{ left, right });

        return error.AssertionFailed;
    }
}

pub fn expectEqualWithType(T: type, left: anytype, right: @TypeOf(left)) error{AssertionFailed}!void {
    if (T != @TypeOf(left)) {
        std.debug.print("type expected: {s} != actual: {s}\n", .{ lib.primitive.types.toString(T), lib.primitive.types.toString(@TypeOf(left)) });

        return error.AssertionFailed;
    }

    if (!lib.common.equal(left, right)) {
        std.debug.print("left: {any} != right: {any}\n", .{ left, right });

        return error.AssertionFailed;
    }
}

pub fn expectEqualString(left: []const u8, right: []const u8) error{AssertionFailed}!void {
    if (!lib.common.equal(left, right)) {
        std.debug.print("left: \"{s}\"({d}) != right: \"{s}\"({d})\n", .{ left, left.len, right, right.len });

        return error.AssertionFailed;
    }
}

test {
    std.testing.refAllDecls(@This());
}
