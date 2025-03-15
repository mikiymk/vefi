//! ライブラリっぽいものを作ってみる

const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const builtin = @import("builtin.zig");

pub const types = @import("types.zig");
pub const collection = @import("collection.zig");
pub const math = @import("math.zig");

pub const common = @import("common.zig");
pub const concept = @import("concept.zig");

pub const string = @import("string.zig");
pub const time = @import("time.zig");

pub const input_output = @import("input_output.zig");
pub const io = input_output;
pub const file_system = struct {};
pub const fs = file_system;
pub const network = struct {};
pub const memory = struct {};

pub const functional = @import("functional.zig");
pub const result = @import("result.zig");
pub const regular_expression = @import("regular_expression.zig");
pub const random = @import("random.zig");
pub const iterator = @import("iterator.zig");

pub const graphic = struct {};
pub const locale = struct {};
pub const parser = @import("parser.zig");
pub const data_format = @import("data_format.zig");
pub const language = struct {
    // 自然言語
};

pub const assert = @import("assert.zig");
pub const testing = @import("testing.zig");
