const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Options = struct {
    sign: Sign,
    bits: u16,

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

    pub fn toBuiltin(self: @This()) std.builtin.Type {
        return .{ .Int = .{
            .signedness = self.sign.toBuiltin(),
            .bits = self.bits,
        } };
    }
};

/// 符号とビット数から整数型を返します。
pub fn Integer(sign: Options.Sign, bits: u16) type {
    return @Type(.{ .Int = .{
        .signedness = sign.toBuiltin(),
        .bits = bits,
    } });
}

test "符号とビットサイズから整数型を作成する" {
    const IntType: type = Integer(.signed, 16);
    try lib.assert.expectEqual(IntType, i16);
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
