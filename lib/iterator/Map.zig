/// 値と型を変更するイテレーター
pub fn Map(Iterator: type, NewType: type) type {
    lib.assert.assert(isIterator(Iterator));
    lib.assert.assert(!lib.types.Optional.isOptional(NewType));
    const T = ItemOf(Iterator);

    return struct {
        pub const Item = NewType;

        iterator: Iterator,
        map_fn: *const fn (value: T) NewType,

        pub fn next(self: *@This()) ?NewType {
            return self.map_fn(self.iterator.next() orelse return null);
        }
    };
}

/// 値を変更したイテレーターを作成する
pub fn map(
    iterator: anytype,
    map_fn: *const fn (value: ItemOf(@TypeOf(iterator))) ItemOf(@TypeOf(iterator)),
) Map(@TypeOf(iterator), ItemOf(@TypeOf(iterator))) {
    return .{
        .iterator = iterator,
        .map_fn = map_fn,
    };
}

/// 値と型を変更したイテレーターを作成する
pub fn mapT(
    T: type,
    iterator: anytype,
    map_fn: *const fn (value: ItemOf(@TypeOf(iterator))) T,
) Map(@TypeOf(iterator), T) {
    return .{
        .iterator = iterator,
        .map_fn = map_fn,
    };
}
