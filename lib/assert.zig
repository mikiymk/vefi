//!

const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

/// 条件を満たしているか確認する。
/// 条件を満たさない場合、ランタイムセーフティが有効ならエラーを起こす。
pub fn assert(ok: bool) void {
    if (!ok) {
        unreachable;
    }
}

pub const ExpectError = error{NotExpected};

fn printL(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}

pub fn expect(ok: bool) ExpectError!void {
    if (!ok) {
        printL("expect failed", .{});

        return error.NotExpected;
    }
}

pub fn expectEqualP(value: anytype, expected: @TypeOf(value)) ExpectError!void {
    if (value != expected) {
        printL("expect failed: value = {any}, expected = {any}", .{ value, expected });

        return error.NotExpected;
    }
}

pub fn expectEqual(expected: anytype, actual: @TypeOf(expected)) ExpectError!void {
    if (!lib.common.equal(expected, actual)) { // TODO
        printL("expect failed: expected = {any}, actual = {any}", .{ expected, actual });

        return error.NotExpected;
    }
}

pub fn expectEqualStruct(expected: anytype, actual: @TypeOf(expected)) ExpectError!void {
    if (!lib.common.equal(expected, actual)) {
        printL("expect failed: expected = {any}, actual = {any}", .{ expected, actual });

        return error.NotExpected;
    }
}

pub fn expectError(expected: anytype, actual: anyerror) ExpectError!void {
    if (expected) {
        printL("expect failed: expected = {any}, actual = {any}({d})", .{ expected, actual, @intFromError(actual) });

        return error.NotExpected;
    } else |e| if (e != actual) {
        printL("expect failed: expected = {any}({d}), actual = {any}({d})", .{ expected, @intFromError(e), actual, @intFromError(actual) });

        return error.NotExpected;
    }
}

pub fn expectType(expected: type, actual: type) ExpectError!void {
    const toString = lib.types.typeName;
    if (expected != actual) {
        printL("expect failed: expected = {s}, actual = {s}", .{ toString(expected), toString(actual) });

        return error.NotExpected;
    }
}

pub fn expectEqualSlice(T: type, expected: []const T, actual: []const T) ExpectError!void {
    if (!lib.common.equal(expected, actual)) {
        printL("expect failed: expected = {any}, actual = {any}", .{ expected, actual });

        return error.NotExpected;
    }
}

pub fn expectEqualString(expected: []const u8, actual: []const u8) ExpectError!void {
    if (!lib.common.equal(expected, actual)) {
        printL("expect failed: expected = \"{s}\"({d}), actual = \"{s}\"({d})", .{ expected, expected.len, actual, actual.len });

        return error.NotExpected;
    }
}

pub fn expectEqualApproximate(expected: anytype, actual: @TypeOf(expected), tolerance: @TypeOf(expected)) ExpectError!void {
    if (!lib.math.float_point.equalApproximateAbsolute(expected, actual, tolerance)) {
        printL("expect failed: expected = {x}, actual = {x}", .{ expected, actual });
        printL("               tolerance = {x} > {x}", .{ @abs(expected - actual), tolerance });

        return error.NotExpected;
    }
}
