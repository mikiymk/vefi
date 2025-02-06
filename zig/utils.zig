//! ユーティリティ関数群

/// 使用しない変数を使用するための関数
pub fn consume(_: anytype) void {}

/// valueがtrueであることを確認します。
pub fn assert(value: bool) !void {
    if (!value) {
        return error.AssertionFailed;
    }
}

pub fn equalSlices(left: anytype, right: @TypeOf(left)) bool {
    return left.len == right.len and for (left, right) |l, r| {
        if (l != r) break false;
    } else true;
}

pub fn equalApprox(left: anytype, right: @TypeOf(left), tolerance: @TypeOf(left)) bool {
    return @abs(left - right) < tolerance;
}
