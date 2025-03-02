const std = @import("std");
const lib = @import("../root.zig");

/// 符号付き・符号無し
pub const Sign = enum(u1) {
    signed,
    unsigned,

    pub fn toBuiltin(self: @This()) std.builtin.Signedness {
        return switch (self) {
            .signed => .signed,
            .unsigned => .unsigned,
        };
    }
};

/// 符号とビット数から整数型を返します。
pub fn Integer(sign: Sign, bits: u16) type {
    return @Type(.{ .Int = .{
        .signedness = sign.toBuiltin(),
        .bits = bits,
    } });
}

test "📖Integer" {
    const IntType: type = Integer(.signed, 16);
    try lib.assert.expectEqualStruct(IntType, i16);
}

/// 整数型を受け取り、同じビット数の符号あり整数を返します。
pub fn Signed(Number: type) type {
    return Integer(.signed, @bitSizeOf(Number));
}

test "📖Signed" {
    try lib.assert.expectEqualStruct(Signed(usize), isize);
    try lib.assert.expectEqualStruct(Signed(isize), isize);
}

/// 整数型を受け取り、同じビット数の符号なし整数を返します。
pub fn Unsigned(Number: type) type {
    return Integer(.unsigned, @bitSizeOf(Number));
}

test "📖Unsigned" {
    try lib.assert.expectEqualStruct(Unsigned(usize), usize);
    try lib.assert.expectEqualStruct(Unsigned(isize), usize);
}

/// 型が整数かどうかを判定します。
pub fn isInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .Int or info == .ComptimeInt;
}

fn digitCount(comptime int: anytype, comptime radix: u6) usize {
    var digit_count: usize = 0;
    var int_remain = int;

    while (int_remain > 0) : (int_remain /= radix) {
        digit_count += 1;
    }

    if (digit_count == 0) {
        return 1;
    }

    return digit_count;
}

pub fn toStringComptime(comptime int: anytype, comptime radix: u6) [digitCount(int, radix):0]u8 {
    comptime lib.assert.assert(isInteger(@TypeOf(int)));
    const digits: []const u8 = "0123456789abcdefghijklmnopqrstuvwxyz";

    var str: [digitCount(int, radix):0]u8 = undefined;
    var int_remain = int;

    var reverse_index = 0;
    while (reverse_index < str.len) : (reverse_index += 1) {
        const index = str.len - reverse_index - 1;
        str[index] = digits[int_remain % radix];
        int_remain /= radix;
    }

    str[str.len] = 0;

    return str;
}
