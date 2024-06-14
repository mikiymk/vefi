
pub const U8 = struct {
    value: u8,

    pub const size: ?usize = 1;

    pub fn parse(bytes: []u8) struct { @This(), usize } {
        const value = bytes[0];

        return .{ .{ value = value }, 1 };
    }

    pub fn serialize(self: @This(), buf: *[]u8) []u8 {
        buf[0] = self.value;

        return buf[0..1];
    }
};

pub const U16be = struct {
    value: u16,

    pub const size: ?usize = 2;

    pub fn parse(bytes: []u8) struct { @This(), usize } {
        const value = bytes[0] * 0xff + bytes[1];

        return .{ .{ value = value }, 2 };
    }

    pub fn serialize(self: @This(), buf: *[]u8) []u8 {
        buf[0] = self.value / 0xff;
        buf[1] = self.value % 0xff;

        return buf[0..2];
    }
};

pub const U16le = struct {
    value: u16,

    pub const size: ?usize = 2;

    pub fn parse(bytes: []u8) struct { @This(), usize } {
        const value = bytes[1] * 0xff + bytes[0];

        return .{ .{ value = value }, 2 };
    }

    pub fn serialize(self: @This(), buf: *[]u8) []u8 {
        buf[1] = self.value / 0xff;
        buf[0] = self.value % 0xff;

        return buf[0..2];
    }
};
