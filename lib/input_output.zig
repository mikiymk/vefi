//!
//!

const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn expectWriter(writer: anytype) !void {
    const size = try writer.write("abc");

    if (3 < size) {
        return error.WrongImplement;
    }
}
