const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn Fixed(length: usize) type {
    return struct {
        pub const value_type: type = [length]u8;
        pub const size: ?usize = null;

        pub fn parse(bytes: []const u8) struct { value_type, usize } {
            var value: value_type = undefined;
            @memcpy(&value, bytes);

            return .{ value, length };
        }

        pub fn serialize(self: value_type, buf: []u8) []u8 {
            @memcpy(buf[0..self.len], &self);

            return buf[0..self.len];
        }
    };
}
