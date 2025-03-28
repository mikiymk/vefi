pub fn SliceIterator(T: type, options: Options) type {return struct {
    pub const Item = T;

    slice: []const T,
    index: usize = 0,

    pub fn next(self: @This()) ?Item {
         switch (options.direction) {
             .forward => {
                if (self.index < self.slice.len) {
                     defer self.index += 1;
                     return self.slice[self.index];
                  } else {
                     return null;
                  }
             },
             .reverse => {
                    if (0 < self.index) {
                      self.index -= 1;
                     return self.slice[self.index];
                  } else {
                     return null;
                  }
             },
         }
    }
};}

pub fn sliceIterator(slice: []const T) SliceIterator(T, .{}) {
    return .{ .slice = slice, .index = 0, };
}

pub fn reversedSliceIterator(slice: []const T) SliceIterator(T, .{ .direction = .reverse }) {
    return .{ .slice = slice, .index = slice.len, };
}
