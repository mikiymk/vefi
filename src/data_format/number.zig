//!

const lib = @import("../root.zig");

const is_big_endian = lib.builtin.endian == .big;

pub const byte = struct {
    pub const value_type: type = u8;
    pub const size: ?usize = 1;

    pub fn parse(bytes: []const u8) struct { value_type, usize } {
        const value = bytes[0];

        return .{ value, 1 };
    }

    pub fn serialize(self: value_type, buf: []u8) []u8 {
        buf[0] = self;

        return buf[0..1];
    }
};

test "parse unsigned int 8bit" {
    const slice: []const u8 = &[_]u8{ 0x01, 0x23, 0x45, 0x67 };

    {
        const parsed, const length = byte.parse(slice);

        try lib.assert.expectEqual(parsed, 0x01);
        try lib.assert.expectEqual(length, 1);
    }

    {
        const parsed, const length = byte.parse(slice[1..]);

        try lib.assert.expectEqual(parsed, 0x23);
        try lib.assert.expectEqual(length, 1);
    }
}

test "serialize unsigned int 8bit" {
    var array = [_]u8{0} ** 4;
    var slice: []u8 = &array;

    _ = byte.serialize(0x45, slice);
    _ = byte.serialize(0x67, slice[2..]);

    try lib.assert.expectEqualSlice(u8, slice, &.{ 0x45, 0, 0x67, 0 });
}

pub const u16_be = struct {
    pub const value_type: type = u16;
    pub const size: ?usize = 2;

    pub fn parse(bytes: []const u8) struct { value_type, usize } {
        var value: value_type = bytes[0];
        value *= 0x100;
        value += bytes[1];

        return .{ value, 2 };
    }

    pub fn serialize(self: value_type, buf: []u8) []u8 {
        buf[0] = @intCast(self / 0x100);
        buf[1] = @intCast(self % 0x100);

        return buf[0..2];
    }
};

test "parse unsigned int big endian 16bit" {
    const slice: []const u8 = &[_]u8{ 0x01, 0x23, 0x45, 0x67 };

    {
        const parsed, const length = u16_be.parse(slice);

        try lib.assert.expectEqual(parsed, 0x0123);
        try lib.assert.expectEqual(length, 2);
    }

    {
        const parsed, const length = u16_be.parse(slice[1..]);

        try lib.assert.expectEqual(parsed, 0x2345);
        try lib.assert.expectEqual(length, 2);
    }
}

test "serialize unsigned int big endian 16bit" {
    var array = [_]u8{0} ** 4;
    var slice: []u8 = &array;

    _ = u16_be.serialize(0x0145, slice);
    _ = u16_be.serialize(0x2367, slice[2..]);

    try lib.assert.expectEqualSlice(u8, slice, &.{ 0x01, 0x45, 0x23, 0x67 });
}

pub const u16_le = struct {
    pub const value_type: type = u16;
    pub const size: ?usize = 2;

    pub fn parse(bytes: []const u8) struct { value_type, usize } {
        var value: value_type = bytes[1];
        value *= 0x100;
        value += bytes[0];

        return .{ value, 2 };
    }

    pub fn serialize(self: value_type, buf: []u8) []u8 {
        buf[1] = @intCast(self / 0x100);
        buf[0] = @intCast(self % 0x100);

        return buf[0..2];
    }
};

test "parse unsigned int little endian 16bit" {
    const slice: []const u8 = &[_]u8{ 0x01, 0x23, 0x45, 0x67 };

    {
        const parsed, const length = u16_le.parse(slice);

        try lib.assert.expectEqual(parsed, 0x2301);
        try lib.assert.expectEqual(length, 2);
    }

    {
        const parsed, const length = u16_le.parse(slice[1..]);

        try lib.assert.expectEqual(parsed, 0x4523);
        try lib.assert.expectEqual(length, 2);
    }
}

test "serialize unsigned int little endian 16bit" {
    var array = [_]u8{0} ** 4;
    var slice: []u8 = &array;

    _ = u16_le.serialize(0x0145, slice);
    _ = u16_le.serialize(0x2367, slice[2..]);

    try lib.assert.expectEqualSlice(u8, slice, &.{ 0x45, 0x01, 0x67, 0x23 });
}
