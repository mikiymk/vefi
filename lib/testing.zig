const std = @import("std");
const lib = @import("root.zig");

fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}

pub const Error = error{NotExpected};

pub fn Expect(T: type) type {
    return struct {
        const E = @This();
        value: T,
        error_stain: ?Error = null,

        fn errored(self: E) Error!void {
            if (self.error_stain) |e| return e;
        }

        pub fn is(self: E, expected: T) Error!void {
            try self.errored();

            if (self.value != expected) {
                print("expect failed: value = {any}, expected = {any}", .{ self.value, expected });

                return error.NotExpected;
            }
        }

        pub fn isNull(self: E) Error!void {
            try self.errored();

            if (self.value != null) {
                print("expect failed: value = {any}, expected = null", .{self.value});

                return error.NotExpected;
            }
        }

        pub fn isType(self: E, expected: type) Error!void {
            const toString = lib.types.typeName;
            try self.errored();

            if (@TypeOf(self.value) != expected) {
                print("expect failed: value = {}({s}), expected = {s}", .{
                    self.value,
                    toString(@TypeOf(self.value)),
                    toString(expected),
                });

                return error.NotExpected;
            }
        }

        pub fn isSlice(self: E, Item: type, expected: []const Item) Error!void {
            try self.errored();
            const actual: []const Item = self.value;

            if (!lib.common.equal(expected, actual)) {
                print("expect failed: expected = {any}, actual = {any}", .{ expected, actual });

                return error.NotExpected;
            }
        }

        pub fn isError(self: E, expected: anyerror) Error!void {
            try self.errored();

            if (self.value) |actual| {
                print("expect failed: expected = {any}({d}), actual = {any}", .{ expected, @intFromError(expected), actual });

                return error.NotExpected;
            } else |err| if (err != expected) {
                print(
                    "expect failed: expected = {any}({d}), actual = {any}({d})",
                    .{ expected, @intFromError(expected), err, @intFromError(err) },
                );

                return error.NotExpected;
            }
        }
    };
}

pub fn expect(value: anytype) Expect(@TypeOf(value)) {
    return .{ .value = value };
}
