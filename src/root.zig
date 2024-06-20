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
const lib = @import("root.zig");

const zig_test = @import("zig_test.zig");

pub const builtin = @import("builtin.zig");

pub const types = struct {
    pub fn typeName(comptime T: type) []const u8 {
        return @typeName(T);
    }
};
pub const collection = @import("collection.zig");
pub const math = @import("math.zig");

pub const common = @import("common.zig");

pub const string = @import("string.zig");
pub const time = @import("time.zig");

pub const input_output = @import("input_output.zig");
pub const file_system = struct {};
pub const network = struct {};
pub const memory = struct {};

pub const result = @import("result.zig");
pub const regular_expression = @import("regular_expression.zig");
pub const graphic = struct {};
pub const random = @import("random.zig");
pub const iterator = @import("iterator.zig");
pub const locale = struct {};

pub const data_format = @import("data_format.zig");
pub const language = struct {
    // 自然言語
};

pub const assert = @import("assert.zig");

test {
    std.testing.refAllDecls(@This());
    _ = zig_test;
}
