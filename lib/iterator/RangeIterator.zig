pub fn RangeIterator(T: type) type {return struct {
    pub const Item = T;
  
    current: Item,
    end: Item,
    step: Item,

    pub fn next(self: @This()) ?Item {
        if (self.step < 0 and self.current < self.end) {
            return null;
        } else if (self.end < self.current) {
            return null;
        } else {
            defer self.current += self.step;
            return self.current;
        }
    }
};}

pub fn range(T: type, start: T, end: T, step: T) RangeIterator(T) {
    return .{
        .current = start,
        .end = end,
        .step = step,
    };
}
