pub fn MapFilter(Iterator: type, T: type) type {
    return struct {
        pub const Item = T;
        iterator: Iterator,
        map_fn: *const fn (value: ItemOf(Iterator)) ?T,
        pub fn next(self: *@This()) ?T {
            while (self.iterator.next()) |value| {
                if (self.map_fn(value)) |mapped_value| {
                    return mapped_value;
                }
            }
            return null;
        }
    };
}
