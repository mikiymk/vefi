const std = @import("std");
const lib = @import("root.zig");

// バイナリファイルの一部

pub const number = @import("data_format/number.zig");

// バイナリファイル

pub const gif = @import("data_format/gif.zig");
pub const jpeg = @import("data_format/jpeg.zig");
pub const png = @import("data_format/png.zig");

// テキストファイル

pub const json = @import("data_format/json.zig");

test {
    std.testing.refAllDecls(@This());
}
