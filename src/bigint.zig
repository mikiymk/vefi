const std = @import("std");

const String = []const u8;
const Array = std.ArrayListUnmanaged(u8);

// X plus Y is Z
// X minus Y is Z
// X multiplied by Y is Z
// X divided by Y is Z

/// multiple precision integer
pub const BigInteger = struct {
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

    fn zero(allocator: std.mem.Allocator) !Self {
        var array = try Array.initCapacity(allocator, 1);
        try array.append(allocator, 0);

        return init(allocator, false, array);
    }

    pub fn from_string(allocator: std.mem.Allocator, string: String) !Self {
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
                array.deinit(allocator);
                return error.InvalidCharacter;
            }
        }

        return init(allocator, is_negative, array);
    }

    pub fn to_string(self: Self) !String {
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

    pub fn deinit(self: *Self) void {
        self.digits.deinit(self.allocator);
    }

    pub fn plus(self: Self, other: Self) !Self {
        if (self.is_negative != other.is_negative) {
            const gt_lt = order_arrays(self.digits, other.digits);

            switch (gt_lt) {
                .gt => {
                    const array = try subtraction_arrays(self.allocator, self.digits, other.digits);
                    return init(self.allocator, self.is_negative, array);
                },
                .lt => {
                    const array = try subtraction_arrays(self.allocator, other.digits, self.digits);
                    return init(self.allocator, other.is_negative, array);
                },
                .eq => {
                    return zero(self.allocator);
                },
            }
        } else {
            var array = try if (self.digits.items.len > other.digits.items.len)
                addition_arrays(self.allocator, self.digits, other.digits)
            else
                addition_arrays(self.allocator, other.digits, self.digits);

            return init(self.allocator, self.is_negative, array);
        }
    }

    pub fn eql(self: Self, other: Self) bool {
        if (self.is_negative != other.is_negative) {
            return false;
        }
        if (self.digits.items.len != other.digits.items.len) {
            return false;
        }

        for (self.digits.items, other.digits.items) |sdigit, odigit| {
            if (sdigit != odigit) {
                return false;
            }
        }

        return true;
    }

    /// if self > other, return .gt (>).
    /// else if self < other, return .lt (<).
    /// else return .eq (=).
    pub fn order(self: Self, other: Self) std.math.Order {
        if (self.is_negative != other.is_negative) {
            if (self.is_negative) {
                return .lt;
            } else {
                return .gt;
            }
        }

        return order_arrays(self.digits, other.digits);
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

fn subtraction_arrays(allocator: std.mem.Allocator, lhs: Array, rhs: Array) !Array {
    var array = try Array.initCapacity(allocator, lhs.items.len + 1);

    const length = @max(lhs.items.len, rhs.items.len);

    for (0..length) |index| {
        var new_digit: u8 = 0;
        if (index < lhs.items.len) {
            new_digit += lhs.items[index];
        }
        if (index < rhs.items.len) {
            new_digit -= rhs.items[index];
        }

        try array.append(allocator, new_digit);
    }

    try carry(allocator, &array);

    return array;
}

fn order_arrays(lhs: Array, rhs: Array) std.math.Order {
    if (lhs.items.len < rhs.items.len) {
        return .lt;
    }
    if (rhs.items.len < lhs.items.len) {
        return .gt;
    }

    var i = lhs.items.len;
    while (i > 0) {
        i -= 1;
        const sdigit = lhs.items[i];
        const odigit = rhs.items[i];

        if (sdigit < odigit) {
            return .lt;
        }
        if (odigit < sdigit) {
            return .gt;
        }
    }

    return .eq;
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
    var bint = try BigInteger.from_string(std.testing.allocator, "1234567890");

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 9, 8, 7, 6, 5, 4, 3, 2, 1 }, bint.digits.items);
    try std.testing.expectEqual(false, bint.is_negative);

    bint.deinit();
}

test "文字列から負の多倍長整数を作る" {
    var bint = try BigInteger.from_string(std.testing.allocator, "-9876543210");

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, bint.digits.items);
    try std.testing.expectEqual(true, bint.is_negative);

    bint.deinit();
}

test "間違った文字列から多倍長整数を作る" {
    var bint = BigInteger.from_string(std.testing.allocator, "012-345-678-9");

    try std.testing.expectError(error.InvalidCharacter, bint);
}

test "同じ多倍長整数を比べる" {
    var bint = try BigInteger.from_string(std.testing.allocator, "1234567890");

    try std.testing.expectEqual(true, bint.eql(bint));

    bint.deinit();
}

test "２つの同じ多倍長整数を比べる" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "1234567890");

    try std.testing.expectEqual(true, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "２つの符号が違う多倍長整数を比べる" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "-1234567890");

    try std.testing.expectEqual(false, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "２つの長さが違う多倍長整数を比べる" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "190");

    try std.testing.expectEqual(false, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "２つの数字が違う多倍長整数を比べる" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "1999999990");

    try std.testing.expectEqual(false, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "繰り上がりのない足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1111111111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "3333333333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "途中に繰り上がりのある足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1111191111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "3333413333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "いちばん上に繰り上がりのある足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "9111111111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "11333333333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "マイナス同士の足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "-1111111111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "-2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "-3333333333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "大きいプラスと小さいマイナスの足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "-1111111111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "1111111111");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "小さいプラスと大きいマイナスの足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1111111111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "-2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "-1111111111");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "同じプラスとマイナスの足し算" {
    var bint1 = try BigInteger.from_string(std.testing.allocator, "1111111111");
    var bint2 = try BigInteger.from_string(std.testing.allocator, "-1111111111");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.from_string(std.testing.allocator, "0");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}
