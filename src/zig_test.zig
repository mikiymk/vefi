//! lib.zig_test
//!
//! Zig言語の基本の書き方を確認する。

const std = @import("std");
const lib = @import("root.zig");

test {
    _ = @import("zig_test/literals.zig");
    _ = @import("zig_test/types.zig");
    _ = @import("zig_test/statements.zig");
    _ = @import("zig_test/type_coercion.zig");
    _ = @import("zig_test/operators.zig");
    _ = @import("zig_test/builtin_functions.zig");
    _ = @import("zig_test/undefined_behaviors.zig");
}

pub const assert = lib.assert;

/// 使用しない変数を使用するための関数
pub fn consume(_: anytype) void {}
