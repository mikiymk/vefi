const std = @import("std");
const lib = @import("ziglib");

test {
    std.testing.refAllDecls(@This());
}

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
        digits: *std.ArrayListUnmanaged(u8),
    ) Self {
        while (digits.getLastOrNull()) |last| {
            if (last == 0) {
                _ = digits.pop();
            } else {
                break;
            }
        }

        const normalized_is_negative = is_negative and digits.items.len != 0;

        return BigInteger{
            .allocator = allocator,
            .is_negative = normalized_is_negative,
            .digits = digits.*,
        };
    }

    pub fn fromInt(comptime T: type, allocator: std.mem.Allocator, value: T) !Self {
        const typeinfo = @typeInfo(@TypeOf(value));
        std.debug.assert(typeinfo == .Int);

        const bits = l: {
            if (typeinfo != .Int) {
                @compileError("compile error");
            }

            if (typeinfo.Int.bits % 8 == 0) {
                break :l typeinfo.Int.bits / 8 + 0;
            } else {
                break :l typeinfo.Int.bits / 8 + 1;
            }
        };

        var array = try Array.initCapacity(allocator, bits);

        var var_value = value;
        while (var_value != 0) {
            try array.append(allocator, @truncate(var_value));

            if (typeinfo.Int.bits > 8) {
                var_value >>= 8;
            }
        }

        return init(allocator, false, &array);
    }

    pub fn fromString(allocator: std.mem.Allocator, string: String) !Self {
        var array = try Array.initCapacity(allocator, string.len);
        errdefer array.deinit(allocator);

        const is_negative = string[0] == '-';
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

        return init(allocator, is_negative, &array);
    }

    pub fn toString(self: Self) !String {
        var array = std.ArrayList(u8).init(self.allocator);

        if (self.is_negative) {
            try array.append('-');
        }

        var i = self.digits.items.len;
        while (i > 0) {
            i -= 1;
            const digit = self.digits.items[i];

            // 0 .. 255
            var buf: [3]u8 = .{ 0, 0, 0 };
            const fmt_result = try std.fmt.bufPrint(&buf, "{d}", .{digit});

            try array.appendSlice(fmt_result);
            try array.append(',');
        }

        if (array.items.len == 0) {
            try array.append('0');
        }

        return array.toOwnedSlice();
    }

    pub fn deinit(self: *Self) void {
        self.digits.deinit(self.allocator);
    }

    pub fn plus(self: Self, other: Self) !Self {
        if (self.is_negative != other.is_negative) {
            const gt_lt = orderArrays(self.digits, other.digits);

            switch (gt_lt) {
                .gt => {
                    var array = try subtractionArrays(self.allocator, self.digits, other.digits);
                    return init(self.allocator, self.is_negative, &array);
                },
                .lt => {
                    var array = try subtractionArrays(self.allocator, other.digits, self.digits);
                    return init(self.allocator, other.is_negative, &array);
                },
                .eq => {
                    return fromInt(u8, self.allocator, 0);
                },
            }
        } else {
            var array = try if (self.digits.items.len > other.digits.items.len)
                additionArrays(self.allocator, self.digits, other.digits)
            else
                additionArrays(self.allocator, other.digits, self.digits);

            return init(self.allocator, self.is_negative, &array);
        }
    }

    pub fn minus(self: Self, other: Self) !Self {
        // a - b

        if (self.is_negative == other.is_negative) {
            // (a > 0 and b > 0) or (a < 0 and b < 0)
            const gt_lt = orderArrays(self.digits, other.digits);

            switch (gt_lt) {
                .gt => {
                    // if |a| > |b|, a - b = sign(a) * (|a| - |b|)
                    var array = try subtractionArrays(self.allocator, self.digits, other.digits);
                    return init(self.allocator, self.is_negative, &array);
                },
                .lt => {
                    // if |a| < |b|, a - b = -sign(a) * (|b| - |a|)
                    var array = try subtractionArrays(self.allocator, other.digits, self.digits);
                    return init(self.allocator, !self.is_negative, &array);
                },
                .eq => {
                    // if |a| = |b|, a - b = 0
                    return fromInt(u8, self.allocator, 0);
                },
            }
        } else {
            // (a > 0 and b < 0) or (a < 0 and b > 0)

            var array = try if (self.digits.items.len > other.digits.items.len)
                additionArrays(self.allocator, self.digits, other.digits)
            else
                additionArrays(self.allocator, other.digits, self.digits);

            return init(self.allocator, self.is_negative, &array);
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

        return orderArrays(self.digits, other.digits);
    }
};

fn additionArrays(allocator: std.mem.Allocator, lhs: Array, rhs: Array) !Array {
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

fn subtractionArrays(allocator: std.mem.Allocator, lhs: Array, rhs: Array) !Array {
    var array = try Array.initCapacity(allocator, lhs.items.len + 1);
    var prev_carry: i2 = 0;

    const length = @max(lhs.items.len, rhs.items.len);

    for (0..length) |index| {
        var ldigit: u8 = undefined;
        var rdigit: u8 = undefined;
        if (index < lhs.items.len) {
            ldigit = lhs.items[index];
        } else {
            ldigit = 0;
        }

        if (index < rhs.items.len) {
            rdigit = rhs.items[index];
        } else {
            rdigit = 0;
        }

        const new_digit = carry_minus(ldigit, rdigit, prev_carry);
        prev_carry = new_digit.carry;

        try array.append(allocator, new_digit.sum);
    }

    try carry(allocator, &array);

    return array;
}

/// if lhs > rhs, return gt.
/// else if lhs < rhs, return lt.
/// else return eq.
fn orderArrays(lhs: Array, rhs: Array) std.math.Order {
    if (lhs.items.len < rhs.items.len) {
        return .lt;
    }
    if (rhs.items.len < lhs.items.len) {
        return .gt;
    }

    var i = lhs.items.len;
    while (i > 0) {
        i -= 1;
        const ldigit = lhs.items[i];
        const rdigit = rhs.items[i];

        if (ldigit < rdigit) {
            return .lt;
        }
        if (rdigit < ldigit) {
            return .gt;
        }
    }

    return .eq;
}

fn carry(allocator: std.mem.Allocator, array: *Array) !void {
    for (0..array.items.len - 1) |index| {
        const digit = array.items[index];
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

const Carry = struct {
    sum: u8,
    carry: i2,
};

// 0 - 9     => 1, -1
// 0 - 9 - 1 => 0, -1
fn carry_minus(left: u8, right: u8, carried: i2) Carry {
    const sum: i16 = @as(i16, left) - @as(i16, right) + @as(i16, carried);
    if (sum < 0) {
        return .{
            .sum = @intCast(10 + sum),
            .carry = -1,
        };
    } else {
        return .{
            .sum = @intCast(sum),
            .carry = 0,
        };
    }
}

test "文字列から正の多倍長整数を作る" {
    var bint = try BigInteger.fromString(std.testing.allocator, "1234567890");

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 9, 8, 7, 6, 5, 4, 3, 2, 1 }, bint.digits.items);
    try std.testing.expectEqual(false, bint.is_negative);

    bint.deinit();
}

test "文字列から負の多倍長整数を作る" {
    var bint = try BigInteger.fromString(std.testing.allocator, "-9876543210");

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, bint.digits.items);
    try std.testing.expectEqual(true, bint.is_negative);

    bint.deinit();
}

test "間違った文字列から多倍長整数を作る" {
    const bint = BigInteger.fromString(std.testing.allocator, "012-345-678-9");

    try std.testing.expectError(error.InvalidCharacter, bint);
}

test "同じ多倍長整数を比べる" {
    var bint = try BigInteger.fromString(std.testing.allocator, "1234567890");

    try std.testing.expectEqual(true, bint.eql(bint));

    bint.deinit();
}

test "２つの同じ多倍長整数を比べる" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "1234567890");

    try std.testing.expectEqual(true, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "２つの符号が違う多倍長整数を比べる" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "-1234567890");

    try std.testing.expectEqual(false, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "２つの長さが違う多倍長整数を比べる" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "190");

    try std.testing.expectEqual(false, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "２つの数字が違う多倍長整数を比べる" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1234567890");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "1999999990");

    try std.testing.expectEqual(false, bint1.eql(bint2));

    bint1.deinit();
    bint2.deinit();
}

test "繰り上がりのない足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1111111111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "3333333333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "途中に繰り上がりのある足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1111191111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "3333413333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "いちばん上に繰り上がりのある足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "9111111111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "11333333333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "マイナス同士の足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "-1111111111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "-2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "-3333333333");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "大きいプラスと小さいマイナスの足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "-1111111111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "1111111111");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "小さいプラスと大きいマイナスの足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1111111111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "-2222222222");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "-1111111111");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "同じプラスとマイナスの足し算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "1111111111");
    var bint2 = try BigInteger.fromString(std.testing.allocator, "-1111111111");

    var actual = try bint1.plus(bint2);
    var expected = try BigInteger.fromString(std.testing.allocator, "0");

    try std.testing.expect(expected.eql(actual));

    bint1.deinit();
    bint2.deinit();
    actual.deinit();
    expected.deinit();
}

test "繰り下がりのない引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "2222222222");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "1111111111");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "1111111111");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}

test "途中に繰り下がりのある引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "2222222222");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "1111191111");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "1111031111");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}

test "連鎖する繰り下がりのある引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "10000000000");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "9999999999");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "1");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}

test "引く数のほうが大きい引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "2200000000");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "2300000000");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "-100000000");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}

test "マイナス同士の引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "-9876543210");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "-8876543210");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "-1000000000");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}

test "プラスとマイナスの引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "9876543210");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "-1234567890");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "11111111100");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}

test "マイナスとプラスの引き算" {
    var bint1 = try BigInteger.fromString(std.testing.allocator, "-9876543210");
    defer bint1.deinit();

    var bint2 = try BigInteger.fromString(std.testing.allocator, "1234567890");
    defer bint2.deinit();

    var actual = try bint1.minus(bint2);
    defer actual.deinit();

    var expected = try BigInteger.fromString(std.testing.allocator, "-11111111100");
    defer expected.deinit();

    try std.testing.expect(expected.eql(actual));
}
