//! ユーティリティ関数群

/// 使用しない変数を使用するための関数
pub fn consume(_: anytype) void {}

/// valueがtrueであることを確認します。
pub fn assert(value: bool) !void {
    if (!value) {
        return error.AssertionFailed;
    }
}
