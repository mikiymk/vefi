//! 標準ライブラリっぽいものを作ってみる
//! 参考
//! zig https://ziglang.org/documentation/master/std/
//! java https://docs.oracle.com/javase/jp/21/docs/api/index.html
//! python https://docs.python.org/ja/3/library/index.html
//! c++ https://cpprefjp.github.io/reference.html
//! rust https://doc.rust-lang.org/std/
//! go https://pkg.go.dev/std

pub const collection = struct {
  pub const array_list = @import("array_list");
  pub const linked_list = @import("array_list");
  pub const doubly_linked_list = @import("array_list");
  pub const circular_linked_list = @import("array_list");
  pub const doubly_circular_linked_list = @import("array_list");
};

pub const math = struct {
  pub const complex = @import("complex");
};

pub const datetime = @import("array_list");
