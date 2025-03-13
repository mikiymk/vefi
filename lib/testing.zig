const std = @import("std");
const lib = @import("root.zig");
const NotError = lib.types.error_union.Value;
const NotOptional = lib.types.Optional.NonOptional;

fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}

pub fn Expect(T: type) type {
    return struct {
        const E = @This();
        value: T,
        error_stain: ?anyerror = null,

        fn checkError(self: E) !void {
            if (self.error_stain) |e| return e;
        }

        pub fn err(self: E) Expect(NotError(T)) {
            if (self.value) |v| {
                return .{ .value = v };
            } else |e| {
                return .{ .value = undefined, .error_stain = e };
            }
        }

        pub fn opt(self: E) Expect(NotOptional(T)) {
            if (self.value) |v| {
                return .{ .value = v };
            } else {
                return .{ .value = undefined, .error_stain = error.OptionalIsNull };
            }
        }

        pub fn is(self: E, expected: T) !void {
            try self.checkError();

            if (self.value != expected) {
                print("expect failed: value = {any}, expected = {any}", .{ self.value, expected });

                return error.NotExpected;
            }
        }

        pub fn isNull(self: E) !void {
            try self.checkError();

            if (self.value != null) {
                print("expect failed: value = {any}, expected = null", .{self.value});

                return error.NotExpected;
            }
        }

        pub fn isType(self: E, expected: type) !void {
            const toString = lib.types.typeName;
            try self.checkError();

            if (@TypeOf(self.value) != expected) {
                print("expect failed: value = {}({s}), expected = {s}", .{
                    self.value,
                    toString(@TypeOf(self.value)),
                    toString(expected),
                });

                return error.NotExpected;
            }
        }

        pub fn isSlice(self: E, Item: type, expected: []const Item) !void {
            try self.checkError();
            const actual: []const Item = self.value;

            if (!lib.common.equal(expected, actual)) {
                print("expect failed: expected = {any}, actual = {any}", .{ expected, actual });

                return error.NotExpected;
            }
        }

        pub fn isString(self: E, expected: []const u8) !void {
            try self.checkError();

            const actual: []const u8 = self.value;
            if (!lib.common.equal(expected, actual)) {
                print("expect failed: expected = {s}, actual = {s}", .{ expected, actual });

                return error.NotExpected;
            }
        }

        pub fn isError(self: E, expected: anyerror) !void {
            try self.checkError();

            if (self.value) |actual| {
                print("expect failed: expected = {any}({d}), actual = {any}", .{ expected, @intFromError(expected), actual });

                return error.NotExpected;
            } else |e| if (e != expected) {
                print(
                    "expect failed: expected = {any}({d}), actual = {any}({d})",
                    .{ expected, @intFromError(expected), e, @intFromError(e) },
                );

                return error.NotExpected;
            }
        }
    };
}

pub fn expect(value: anytype) Expect(@TypeOf(value)) {
    return .{ .value = value };
}
