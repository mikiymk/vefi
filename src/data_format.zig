const std = @import("std");
const lib = @import("./lib.zig");

// バイナリファイルの一部

// バイナリファイル

pub const gif = @import("data_format/gif.zig");
pub const jpeg = @import("data_format/jpeg.zig");
pub const png = @import("data_format/png.zig");

// テキストファイル

pub const json = @import("data_format/json.zig");

test {
    std.testing.refAllDecls(@This());
}
