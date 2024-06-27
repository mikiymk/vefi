const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;
const AllocatorError = Allocator.Error;

/// 動的配列
pub fn DynamicArray(T: type) type {
    return struct {
        value: []T,
        size: usize,

        pub fn init() @This() {
            return .{
                .value = &[_]T{},
                .size = 0,
            };
        }

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.value);
        }

        pub fn push(self: *@This(), allocator: Allocator, item: T) AllocatorError!void {
            if (self.value.len <= self.size) {
                try self.extendSize(allocator);
            }

            self.value[self.size] = item;
            self.size += 1;
        }

        pub fn pop() void {}

        pub fn get(n: usize) *T {
            _ = n;
        }

        pub fn insert(self: *@This(), allocator: Allocator, index: usize, item: T) AllocatorError!void {
            if (self.value.len <= self.size) {
                try self.extendSize(allocator);
            }

            var value = item;
            for (self.value[index .. self.size + 1], 0..) |e, i| {
                self.value[i] = value;
                value = e;
            }

            self.value[index] = item;
            self.size += 1;
        }

        pub fn delete(n: usize) void {
            _ = n;
        }

        pub fn copyToSlice(self: @This(), allocator: Allocator) AllocatorError![]const T {
            var slice = try allocator.alloc(T, self.size);
            @memcpy(slice[0..self.size], self.value[0..self.size]);

            return slice;
        }

        pub fn moveToSlice(self: *@This(), allocator: Allocator) AllocatorError![]const T {
            const slice = try self.copyToSlice(allocator);
            self.deinit();

            return slice;
        }

        fn extendSize(self: *@This(), allocator: Allocator) AllocatorError!void {
            const new_length = if (self.size == 0) 5 else self.size * 2;

            var old_values = self.value;
            var new_values = try allocator.alloc(T, new_length);

            @memcpy(new_values[0..self.size], old_values[0..self.size]);

            self.value = new_values;
            allocator.free(old_values);
        }
    };
}
