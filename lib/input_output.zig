//!
//!

const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

/// 出力のラッピングをする。
pub fn Writer(W: type) type {
    return struct {
        writer: W,

        pub const Error = W.Error;

        pub inline fn write(self: @This(), bytes: []const u8) Error!usize {
            return self.writer.write(bytes);
        }

        pub inline fn writeAll(self: @This(), bytes: []const u8) Error!void {
            return self.writer.writeAll(bytes);
        }

        pub inline fn print(self: @This(), comptime format: []const u8, args: anytype) Error!void {
            return self.writer.print(format, args);
        }

        pub inline fn writeByte(self: @This(), byte: u8) Error!void {
            return self.writer.writeByte(byte);
        }

        pub inline fn writeByteNTimes(self: @This(), byte: u8, n: usize) Error!void {
            return self.writer.writeByteNTimes(byte, n);
        }

        pub inline fn writeBytesNTimes(self: @This(), bytes: []const u8, n: usize) Error!void {
            return self.writer.writeBytesNTimes(bytes, n);
        }

        pub inline fn writeInt(self: @This(), comptime T: type, value: T, endian: std.builtin.Endian) Error!void {
            return self.writer.writeInt(T, value, endian);
        }

        pub inline fn writeStruct(self: @This(), value: anytype) Error!void {
            return self.writer.writeStruct(value);
        }

        pub inline fn writeStructEndian(self: @This(), value: anytype, endian: std.builtin.Endian) Error!void {
            return self.writer.writeStructEndian(value, endian);
        }
    };
}

pub inline fn writer(w: anytype) Writer(@TypeOf(w)) {
    return .{ .writer = w };
}

pub fn expectWriter(w: anytype) !void {
    const size = try w.write("abc");

    if (3 < size) {
        return error.WrongImplement;
    }
}
