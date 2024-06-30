const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

// バイナリファイルの一部

pub const number = @import("data_format/number.zig");
pub const string = @import("data_format/string.zig");
pub const utils = @import("data_format/utils.zig");

// バイナリファイル

pub const gif = @import("data_format/gif.zig");
pub const jpeg = @import("data_format/jpeg.zig");
pub const png = @import("data_format/png.zig");

// テキストファイル

pub const json = @import("data_format/json.zig");
