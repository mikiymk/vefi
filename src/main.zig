const std = @import("std");

// X plus Y is Z
// X minus Y is Z
// X multiplied by Y is Z
// X divided by Y is Z

/// multiple precision integer
const BigInteger = struct {
    allocator: std.mem.Allocator,

    is_negative: bool,
    digits: std.ArrayListUnmanaged(u8),

    const Self = @This();

    fn from_string(allocator: std.mem.Allocator, string: []const u8) !Self {
        var array = try std.ArrayListUnmanaged(u8).initCapacity(allocator, string.len);
        var is_first = true;
        var is_negative = false;

        for (string) |char| {
            if (is_first and char == '-') {
                is_negative = true;
                continue;
            }

            if ('0' <= char and char <= '9') {
                try array.append(allocator, char - '0');
            } else {
                return error.AugumentError;
            }
        }

        return BigInteger{
            .allocator = allocator,

            .is_negative = is_negative,
            .digits = array,
        };
    }

    fn to_string(self: *const Self) ![]const u8 {
        var array = std.ArrayList(u8).init(self.allocator);

        if (self.is_negative) {
            try array.append('-');
        }

        for (self.digits.items) |digit| {
            try array.append(digit + '0');
        }

        return array.toOwnedSlice();
    }
};

fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    const testing = std.testing;

    try testing.expect(add(3, 7) == 10);
}

pub fn main() !void {
    const print = std.debug.print;

    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "-9876543210");
    const bint3 = try BigInteger.from_string(std.heap.page_allocator, "9999999999999999999999");

    print("hello zig {!s} {!s} {!s}", .{ bint1.to_string(), bint2.to_string(), bint3.to_string() });
}
