//! 標準ライブラリっぽいものを作ってみる
//! 参考
//! zig https://ziglang.org/documentation/master/std/
//! java https://docs.oracle.com/javase/jp/21/docs/api/index.html
//! python https://docs.python.org/ja/3/library/index.html
//! c++ https://cpprefjp.github.io/reference.html
//! rust https://doc.rust-lang.org/std/
//! go https://pkg.go.dev/std
//! ruby https://docs.ruby-lang.org/ja/latest/doc/index.html
//! php https://www.php.net/manual/ja/funcref.php

const std = @import("std");
const lib = @import("./lib.zig");

pub const primitive = @import("primitive.zig");
pub const collection = @import("collection.zig");
pub const math = @import("math.zig");
pub const common = @import("common.zig");

pub const string = @import("string.zig");
pub const time = @import("time.zig");

pub const input_output = @import("input_output.zig");
pub const file_system = struct {};
pub const network = struct {};
pub const memory = struct {};

pub const regular_expression = struct {};
pub const graphic = struct {};
pub const types = struct {
    pub fn typeName(comptime T: type) []const u8 {
        return @typeName(T);
    }
};

pub const random = struct {};
pub const locale = struct {};

pub const file_format = @import("file_format.zig");
pub const language = struct {
    //! 自然言語
};

pub const assert = @import("assert.zig");

test {
    std.testing.refAllDecls(@This());
}
