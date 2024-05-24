const std = @import("std");
const lib = @import("./lib.zig");

// binary format

pub const jpeg = @import("file_format/jpeg.zig");
pub const png = @import("file_format/png.zig");

// text format

pub const json = @import("file_format/json.zig");

test {
    std.testing.refAllDecls(@This());
}
