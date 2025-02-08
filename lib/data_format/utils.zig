const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn Block(definisions: anytype) type {
    _ = definisions;

    return struct {
        pub const value_type: type = void;
        pub const size: ?usize = null;

        pub fn parse(bytes: []const u8) struct { value_type, usize } {
            _ = bytes;
            const value: void = {};

            return .{ value, 1 };
        }

        pub fn serialize(self: value_type, buf: []u8) []u8 {
            buf[0] = self;

            return buf[0..1];
        }
    };
}

pub fn Pack(byte_size: usize, definisions: anytype) type {
    _ = byte_size;
    _ = definisions;

    return struct {
        pub const value_type: type = void;
        pub const size: ?usize = null;

        pub fn parse(bytes: []const u8) struct { value_type, usize } {
            _ = bytes;
            const value: void = {};

            return .{ value, 1 };
        }

        pub fn serialize(self: value_type, buf: []u8) []u8 {
            buf[0] = self;

            return buf[0..1];
        }
    };
}
