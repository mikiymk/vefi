//! 標準ライブラリっぽいものを実装してみる
//! 参考
//! https://ziglang.org/documentation/master/std/#A;std
//! https://docs.oracle.com/javase/jp/21/docs/api/index.html
//! https://docs.python.org/ja/3/library/index.html
//! https://doc.rust-lang.org/std/

pub const collection = struct {
  pub const array_list = @import("array_list");
  pub const linked_list = @import("array_list");
};

pub const math = struct {
  pub const complex = @import("complex");
};

