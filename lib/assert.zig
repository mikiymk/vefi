const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Error = error{
    AssertionFailed,
};

pub fn assert(ok: bool) void {
    if (!ok) {
        unreachable;
    }
}

pub fn expect(ok: bool) Error!void {
    if (!ok) {
        return error.AssertionFailed;
    }
}

pub fn expectEqual(left: anytype, right: @TypeOf(left)) Error!void {
    if (!lib.common.equal(left, right)) {
        std.debug.print("left: {any} != right: {any}\n", .{ left, right });

        return error.AssertionFailed;
    }
}

pub fn expectEqualWithType(T: type, left: anytype, right: @TypeOf(left)) Error!void {
    if (T != @TypeOf(left)) {
        std.debug.print("type expected: {s} != actual: {s}\n", .{ lib.primitive.types.toString(T), lib.primitive.types.toString(@TypeOf(left)) });

        return error.AssertionFailed;
    }

    if (!lib.common.equal(left, right)) {
        std.debug.print("left: {any} != right: {any}\n", .{ left, right });

        return error.AssertionFailed;
    }
}

pub fn expectEqualSlice(T: type, left: []const T, right: []const T) Error!void {
    if (!lib.common.equal(left, right)) {
        std.debug.print("left: {any} != right: {any}\n", .{ left, right });

        return error.AssertionFailed;
    }
}

pub fn expectEqualString(left: []const u8, right: []const u8) Error!void {
    if (!lib.common.equal(left, right)) {
        std.debug.print("left: \"{s}\"({d}) != right: \"{s}\"({d})\n", .{ left, left.len, right, right.len });

        return error.AssertionFailed;
    }
}

pub fn expectEqualApproximate(left: anytype, right: @TypeOf(left), tolerance: @TypeOf(left)) Error!void {
    if (!lib.math.float_point.equalApproximateAbsolute(left, right, tolerance)) {
        std.debug.print(
            "left: {any} - right: {any} = {any} > {any}\n",
            .{ left, right, @abs(left - right), tolerance },
        );

        return error.AssertionFailed;
    }
}
