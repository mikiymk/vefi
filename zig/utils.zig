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
