//! ユーティリティ関数群

/// 使用しない変数を使用するための関数
pub fn consume(_: anytype) void {}

/// valueがtrueであることを確認します。
pub fn assert(value: bool) !void {
    if (!value) {
        return error.AssertionFailed;
    }
}

/// 2つのスライスを等値比較します。
pub fn equalSlices(left: anytype, right: @TypeOf(left)) bool {
    return left.len == right.len and for (left, right) |l, r| {
        if (l != r) break false;
    } else true;
}

/// 2つの値を近似比較します。
pub fn equalApprox(left: anytype, right: @TypeOf(left), tolerance: @TypeOf(left)) bool {
    return @abs(left - right) < tolerance;
}

const std = @import("std");
const compile_zig = @import("compile-zig.zig");
pub const compileZig = compile_zig.compileZig;
pub const CompileResult = compile_zig.CompileResult;
pub const allocator = std.testing.allocator;
pub const failing_allocator = std.testing.failing_allocator;
