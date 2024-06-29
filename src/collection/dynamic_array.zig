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

        /// 配列を空の状態で初期化する。
        pub fn init() @This() {
            return .{
                .value = &[_]T{},
                .size = 0,
            };
        }

        /// メモリを解放する。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.value);
        }

        /// 値を配列の最も後ろに追加する。
        /// 配列の長さが足りないときは拡張した長さの配列を再確保する。
        pub fn push(self: *@This(), allocator: Allocator, item: T) AllocatorError!void {
            if (self.value.len <= self.size) {
                try self.extendSize(allocator);
            }

            self.value[self.size] = item;
            self.size += 1;
        }

        /// 配列の最も後ろの要素を削除し、その値を返す。
        /// 配列が要素を持たない場合、配列を変化させずにnullを返す。
        pub fn pop(self: *@This()) ?T {
            if (self.size == 0) return null;
            self.size -= 1;
            return self.value[self.size];
        }

        /// 配列の`N`番目の要素を返す。
        /// Nが配列の長さより大きい場合、nullを返す。
        pub fn get(n: usize) ?*T {
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

        pub fn asSlice(self: @This()) []const T {
            return self.value[0..self.size];
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

        /// メモリを再確保して配列の長さを拡張する。
        fn extendSize(self: *@This(), allocator: Allocator) AllocatorError!void {
            const initial_size = 8;
            const extend_factor = 2;

            const old_length = self.value.len;
            const new_length = if (old_length == 0)
                initial_size
            else
                old_length * extend_factor;

            var old_values = self.value;
            var new_values = try allocator.alloc(T, new_length);

            @memcpy(new_values[0..self.size], old_values[0..self.size]);

            allocator.free(old_values);
            self.value = new_values;
        }
    };
}
