/// それぞれの値を変更して出力するイテレーター
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

/// それぞれの値を変更して出力するイテレーター
pub fn map(
    NewType: type,
    iterator: anytype,
    map_fn: *const fn (value: ItemOf(@TypeOf(iterator))) NewType,
) Map(@TypeOf(iterator), NewType) {
    return .{
        .iterator = iterator,
        .map_fn = map_fn,
    };
}
