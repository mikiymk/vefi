/// 条件に合う値のみを出力するイテレーター
pub fn Filter(Iterator: type) type {
    lib.assert.assert(isIterator(Iterator));
    const T = ItemOf(Iterator);

    return struct {
        pub const Item = T;

        iterator: Iterator,
        filter_fn: *const fn (value: T) bool,

        pub fn next(self: *@This()) ?T {
            return while (self.iterator.next()) |n| {
                if (self.filter_fn(n)) {
                    break n;
                }
            } else null;
        }
    };
}

/// 条件に合う値のみを出力するイテレーターを作成する
pub fn filter(
    iterator: anytype,
    filter_fn: *const fn (value: ItemOf(@TypeOf(iterator))) bool,
) Filter(@TypeOf(iterator)) {
    return .{
        .iterator = iterator,
        .filter_fn = filter_fn,
    };
}
