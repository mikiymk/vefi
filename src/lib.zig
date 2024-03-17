//! 標準ライブラリっぽいものを作ってみる
//! 参考
//! zig https://ziglang.org/documentation/master/std/
//! java https://docs.oracle.com/javase/jp/21/docs/api/index.html
//! python https://docs.python.org/ja/3/library/index.html
//! c++ https://cpprefjp.github.io/reference.html
//! rust https://doc.rust-lang.org/std/
//! go https://pkg.go.dev/std

pub const primitive = struct {
    pub const boolean = struct {};
    pub const character = struct {};
    pub const integer = struct {};
    pub const float = struct {};

    pub const optional = @import("primitive/optional.zig");
};

pub const collection = struct {
    pub const dynamic_array = @import("collection/dynamic_array.zig");

    pub const list = @import("collection/list.zig");
    pub const doubly_list = struct {};
    pub const circular_list = struct {};

    pub const stack = struct {};
    pub const queue = struct {};
    pub const priority_queue = struct {};
    pub const double_ended_queue = struct {};

    pub const tree = struct {};
    pub const heap = struct {};

    pub const hash_map = struct {};
    pub const tree_map = struct {};
    pub const bidirectional_map = struct {};
    pub const ordered_map = struct {};

    pub const bit_array = struct {};
};

pub const math = struct {
    pub const integer = struct {};
    pub const ratio = struct {};
    pub const float = struct {};
    pub const complex = struct {};
};

pub const string = struct {
    pub const utf8_string = struct {};
    pub const ascii_string = struct {};
};

pub const datetime = struct {
    pub const date = struct {};
    pub const time = struct {};

    pub const timezone = struct {};
};

pub const input_output = struct {};
pub const file_system = struct {};
pub const network = struct {};
pub const memory = struct {};
pub const regular_expression = struct {};
pub const graphic = struct {};
pub const types = struct {};
pub const random = struct {};
pub const locale = struct {};
pub const file_format = struct {};
pub const computer_language = struct {};
pub const natural_language = struct {};

test {
    const std = @import("std");
    std.testing.refAllDeclsRecursive(@This());
}
