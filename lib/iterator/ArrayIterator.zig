pub fn ArrayIterator(T: type, length: usize) type {
    return struct {
        pub const Item = T;

        array: [length]T,
        index: usize,

        pub fn init(array: [length]T) @This() {
            return .{
                .array = array,
                .index = 0,
            };
        }

        pub fn next(self: @This()) ?Item {
            if (self.index < self.array.len) {
                defer self.index += 1;
                return self.array[self.index];
            } else {
                return null;
            }
        }
    };
}

pub fn array(array: anytype) ArrayIterator(ItemOf(@TypeOf(array)), lengthOf(@TypeOf(array))) {
    return .init(array);
}
