pub fn RangeIterator(T: type) type {return struct {
    pub const Item = T;
  
    current: Item,
    end: Item,
    step: Item,
    pub fn init(start: Item, end: Item) @This() {
        return .{
            .current = start,
            .end = end,
            .step = 1;
        };
    }

    pub fn next(self: @This()) ?Item {
        if (self.end < self.current) {
            return null;
        } else {
            defer self.current += self.step;
            return self.current;
        }
    }
};}
