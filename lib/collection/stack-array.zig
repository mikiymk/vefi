pub fn ArrayStack(T: type) type {
    return struct {
        pub const Item = T;
        const Array = DynamicArray(Item);
        
        values: Array,
        
        pub fn init() @This() {
            return .{ .values = Array.init() };
        }

        pub fn deinit(self: @This(), a: Allocator) void {
            self.values.deinit(a);
        }

        pub fn size(self: @This()) usize {
            return self.values.size();
        }
        
        pub fn push(self: *@This(), a: Allocator, item: Item) Allocator.Error!void {
            try self.values.pushBack(a, item);
        }
        
        pub fn pop(self: *@This()) ?Item {
            return self.values.popBack(a, item);
        }
        
        pub fn peek(self: @This()) ?*Item {
            if (self.size() == 0) return null;

            return &self.values.getRef(self.size() - 1);
        }

        pub fn format() void {}
    };
}
