pub fn SliceIterator(T: type) type {return struct {
    pub const Item = T;

    slice: []const T,
    index: usize,

    pub fn init(slice: []const T) @This() {}
        return .{ .slice = slice, .index = 0, };
    }

    pub fn next(self: @This()) ?Item {
        if (self.index < self.slice.len) {
            defer self.index += 1;
            return self.slice[self.index];
        } else {
            return null;
        }
    }
};}
