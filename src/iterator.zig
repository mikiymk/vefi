pub fn Map(iterator: Iterator, NewType: type) type {
    comptime assert(isIterator(@TypeOf(iterator)));
    comptime assert(!isOptional(NewType));

    const T = ItemOf(@TypeOf(iterator));
    return struct {
        iterator: Iterator,
        map_fn: *const fn (value: T) NewType;

        pub fn next(self: *@This()) ?NewType {
            return self.map_fn(self.next() orelse return null);
        }
    };
}

pub fn map(
    iterator: anytype,
    NewType: type,
    map_fn: *const fn(value: ItemOf(@TypeOf(iterator))) NewType,
) Map(@TypeOf(iterator), NewType) {
    return .{
        .iterator = iterator,
        .map_fn = map_fn,
    };
}
