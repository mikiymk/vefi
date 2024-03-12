//! 標準ライブラリっぽいものを作ってみる
//! 参考
//! zig https://ziglang.org/documentation/master/std/
//! java https://docs.oracle.com/javase/jp/21/docs/api/index.html
//! python https://docs.python.org/ja/3/library/index.html
//! c++ https://cpprefjp.github.io/reference.html
//! rust https://doc.rust-lang.org/std/
//! go https://pkg.go.dev/std

pub const primitive = struct {
    pub const boolean = @import("array_list");
    pub const character = @import("array_list");
    pub const integer = @import("array_list");
    pub const float = @import("array_list");
};

pub const collection = struct {
    pub const array = @import("array_list");

    pub const list = @import("array_list");
    pub const doubly_list = @import("array_list");
    pub const circular_list = @import("array_list");

    pub const stack = @import("array_list");
    pub const queue = @import("array_list");
    pub const priority_queue = @import("array_list");
    pub const double_ended_queue = @import("array_list");

    pub const tree = @import("array_list");
    pub const heap = @import("array_list");

    pub const hash_map = @import("array_list");
    pub const tree_map = @import("array_list");
    pub const bidirectional_map = @import("array_list");
    pub const ordered_map = @import("array_list");

    pub const bit_array = @import("array_list");
};

pub const math = struct {
    pub const integer = @import("array_list");
    pub const ratio = @import("array_list");
    pub const float = @import("array_list");
    pub const complex = @import("array_list");
};

pub const string = struct {
    pub const utf8_string = @import("array_list");
    pub const ascii_string = @import("array_list");
};

pub const datetime = struct {
    pub const date = @import("array_list");
    pub const time = @import("array_list");

    pub const timezone = @import("array_list");
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
