const std = @import("std");
const lib = @import("root.zig");
const NotError = lib.types.error_union.Value;
const NotOptional = lib.types.optional.NonOptional;
const Deref = lib.types.pointer.Deref;

pub fn expect(value: anytype) Expect(@TypeOf(value)) {
    return .{ .value = value };
}

pub fn Expect(T: type) type {
    return union(enum) {
        const E = @This();
        value: T,
        error_stain: anyerror,

        fn checkError(self: E) !void {
            switch (self) {
                .error_stain => |e| return e,
                else => {},
            }
        }

        pub fn ptr(self: E) Expect(Deref(T)) {
            switch (self) {
                .error_stain => |e| return .{ .error_stain = e },
                else => {},
            }

            return .{ .value = self.value.* };
        }

        pub fn opt(self: E) Expect(NotOptional(T)) {
            switch (self) {
                .error_stain => |e| return .{ .error_stain = e },
                else => {},
            }

            if (self.value) |v| {
                return .{ .value = v };
            } else {
                p("expected value, actual = null", .{});
                return .{ .error_stain = error.OptionalIsNull };
            }
        }

        pub fn err(self: E) Expect(NotError(T)) {
            switch (self) {
                .error_stain => |e| return .{ .error_stain = e },
                else => {},
            }

            if (self.value) |v| {
                return .{ .value = v };
            } else |e| {
                p("expected value, actual = {any}({d})", .{ e, @intFromError(e) });
                return .{ .error_stain = e };
            }
        }

        pub fn is(self: E, expected: T) !void {
            try self.checkError();

            if (self.value != expected) {
                p("value = {any}, expected = {any}", .{ self.value, expected });

                return error.NotExpected;
            }
        }

        pub fn isNull(self: E) !void {
            try self.checkError();

            if (self.value != null) {
                p("value = {any}, expected = null", .{self.value});

                return error.NotExpected;
            }
        }

        pub fn isType(self: E, expected: type) !void {
            const toString = lib.types.typeName;
            try self.checkError();

            if (@TypeOf(self.value) != expected) {
                p("value = {}({s}), expected type = {s}", .{
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
                p("expected = {any}, actual = {any}", .{ expected, actual });

                return error.NotExpected;
            }
        }

        pub fn isString(self: E, expected: []const u8) !void {
            try self.checkError();

            const actual: []const u8 = self.value;
            if (!lib.common.equal(expected, actual)) {
                p("expected = {s}, actual = {s}", .{ expected, actual });

                return error.NotExpected;
            }
        }

        pub fn isError(self: E, expected: anyerror) !void {
            try self.checkError();

            if (self.value) |actual| {
                p("expected = {any}({d}), actual = {any}", .{ expected, @intFromError(expected), actual });
                return error.NotExpected;
            } else |e| if (e != expected) {
                p(
                    "expected = {any}({d}), actual = {any}({d})",
                    .{ expected, @intFromError(expected), e, @intFromError(e) },
                );
                return error.NotExpected;
            }
        }
    };
}

fn p(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("expect failed: " ++ fmt ++ "\n", args);
}
