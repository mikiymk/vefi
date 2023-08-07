const std = @import("std");

const String = []const u8;
const Array = std.ArrayListUnmanaged(u8);

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

    fn init(
        allocator: std.mem.Allocator,
        is_negative: bool,
        digits: std.ArrayListUnmanaged(u8),
    ) Self {
        return BigInteger{
            .allocator = allocator,
            .is_negative = is_negative,
            .digits = digits,
        };
    }

    fn from_string(allocator: std.mem.Allocator, string: String) !Self {
        var array = try Array.initCapacity(allocator, string.len);

        var is_negative = string[0] == '-';
        var limit: usize = undefined;
        if (is_negative) {
            limit = 1;
        } else {
            limit = 0;
        }

        var i = string.len;
        while (i > limit) {
            i -= 1;
            const char = string[i];

            if ('0' <= char and char <= '9') {
                try array.append(allocator, char - '0');
            } else {
                return error.InvalidCharacter;
            }
        }

        return init(allocator, is_negative, array);
    }

    fn to_string(self: Self) !String {
        var array = std.ArrayList(u8).init(self.allocator);

        if (self.is_negative) {
            try array.append('-');
        }

        var i = self.digits.items.len;
        while (i > 0) {
            i -= 1;
            const digit = self.digits.items[i];

            try array.append(digit + '0');
        }

        return array.toOwnedSlice();
    }

    fn deinit(self: *Self) void {
        self.digits.deinit(self.allocator);
    }

    fn plus(self: Self, other: Self) !Self {
        if (self.is_negative != other.is_negative) {
            return error.NotImplemented;
        }

        const is_negative = self.is_negative;

        var array = try if (self.digits.items.len > other.digits.items.len)
            addition_arrays(self.allocator, self.digits, other.digits)
        else
            addition_arrays(self.allocator, other.digits, self.digits);

        return init(self.allocator, is_negative, array);
    }

    fn eql(self: Self, other: Self) bool {
        if (self.is_negative != other.is_negative) {
            return false;
        }
        if (self.digits.items.len != other.digits.items.len) {
            return false;
        }

        for (0..self.digits.items.len) |index| {
            if (self.digits.items[index] != other.digits.items[index]) {
                return false;
            }
        }

        return true;
    }
};

fn addition_arrays(allocator: std.mem.Allocator, lhs: Array, rhs: Array) !Array {
    var array = try Array.initCapacity(allocator, lhs.items.len + 1);

    for (0..lhs.items.len) |index| {
        var new_digit = lhs.items[index];
        if (index < rhs.items.len) {
            new_digit += rhs.items[index];
        }

        try array.append(allocator, new_digit);
    }

    try carry(allocator, &array);

    return array;
}

fn carry(allocator: std.mem.Allocator, array: *Array) !void {
    for (0..array.items.len - 1) |index| {
        var digit = array.items[index];
        if (9 < digit) {
            array.items[index + 1] += digit / 10;
            array.items[index] = digit % 10;
        }
    }

    while (array.getLastOrNull()) |last| {
        if (9 < last) {
            array.items[array.items.len - 1] = last % 10;
            try array.append(allocator, last / 10);
        } else {
            break;
        }
    }
}

test "文字列から正の多倍長整数を作る" {
    const bint = try BigInteger.from_string(std.heap.page_allocator, "1234567890");

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 9, 8, 7, 6, 5, 4, 3, 2, 1 }, bint.digits.items);
    try std.testing.expectEqual(false, bint.is_negative);
}

test "文字列から負の多倍長整数を作る" {
    const bint = try BigInteger.from_string(std.heap.page_allocator, "-9876543210");

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, bint.digits.items);
    try std.testing.expectEqual(true, bint.is_negative);
}

test "間違った文字列から多倍長整数を作る" {
    const bint = BigInteger.from_string(std.heap.page_allocator, "012-345-678-9");

    try std.testing.expectError(error.InvalidCharacter, bint);
}

test "同じ多倍長整数を比べる" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");

    try std.testing.expectEqual(true, bint1.eql(bint1));
}

test "２つの同じ多倍長整数を比べる" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");

    try std.testing.expectEqual(true, bint1.eql(bint2));
}

test "２つの符号が違う多倍長整数を比べる" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "-1234567890");

    try std.testing.expectEqual(false, bint1.eql(bint2));
}

test "２つの長さが違う多倍長整数を比べる" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "190");

    try std.testing.expectEqual(false, bint1.eql(bint2));
}

test "２つの数字が違う多倍長整数を比べる" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "1999999990");

    try std.testing.expectEqual(false, bint1.eql(bint2));
}

test "繰り上がりのない足し算" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1111111111");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "2222222222");

    const actual = try bint1.plus(bint2);
    const expected = try BigInteger.from_string(std.heap.page_allocator, "3333333333");

    try std.testing.expect(expected.eql(actual));
}

test "途中に繰り上がりのある足し算" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "1111191111");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "2222222222");

    const actual = try bint1.plus(bint2);
    const expected = try BigInteger.from_string(std.heap.page_allocator, "3333413333");

    try std.testing.expect(expected.eql(actual));
}

test "いちばん上に繰り上がりのある足し算" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "9111111111");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "2222222222");

    const actual = try bint1.plus(bint2);
    const expected = try BigInteger.from_string(std.heap.page_allocator, "11333333333");

    try std.testing.expect(expected.eql(actual));
}

test "マイナス同士の足し算" {
    const bint1 = try BigInteger.from_string(std.heap.page_allocator, "-1111111111");
    const bint2 = try BigInteger.from_string(std.heap.page_allocator, "-2222222222");

    const actual = try bint1.plus(bint2);
    const expected = try BigInteger.from_string(std.heap.page_allocator, "-3333333333");

    try std.testing.expect(expected.eql(actual));
}

pub fn main() !void {
    const print = std.debug.print;

    const stdin = std.io.getStdIn().reader();
    _ = stdin;

    var bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    var bint2 = try BigInteger.from_string(std.heap.page_allocator, "-9876543210");
    var bint3 = try BigInteger.from_string(std.heap.page_allocator, "9999999999999999999999");

    print("hello zig {!s} {!s} {!s}\n", .{ bint1.to_string(), bint2.to_string(), bint3.to_string() });

    bint1.deinit();
    bint2.deinit();
    bint3.deinit();
}
