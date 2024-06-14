const std = @import("std");
const lib = @import("./lib.zig");

// バイナリファイルの一部

// バイナリファイル

pub const gif = @import("file_format/gif.zig");
pub const jpeg = @import("file_format/jpeg.zig");
pub const png = @import("file_format/png.zig");

// テキストファイル

pub const json = @import("file_format/json.zig");

test {
    std.testing.refAllDecls(@This());
}
