const zig_test = @import("../zig_test.zig");
const assert = zig_test.assert;
const consume = zig_test.consume;

test {
    _ = primitive_types;
    _ = arrays;
    _ = vectors;
    _ = pointers;
    _ = slice;
    _ = structs;
    _ = enums;
    _ = unions;
    _ = opaques;
    _ = optionals;
    _ = errors;
}

const primitive_types = struct {
    test "整数型" {
        // 8の倍数の整数型
        const var_01: u8 = 50;
        const var_02: u16 = 500;
        const var_03: u32 = 5000;
        const var_04: u64 = 50000;
        const var_05: u128 = 500000;
        const var_06: usize = 5000000;

        const var_07: i8 = -50;
        const var_08: i16 = -500;
        const var_09: i32 = -5000;
        const var_10: i64 = -50000;
        const var_11: i128 = -500000;
        const var_12: isize = -5000000;

        // 任意幅の整数型
        const var_13: u0 = 0;
        const var_14: i65535 = -40;

        consume(.{ var_01, var_02, var_03, var_04, var_05, var_06, var_07, var_08, var_09, var_10, var_11, var_12, var_13, var_14 });
    }

    test "浮動小数点数型" {
        const var_01: f16 = 0.01;
        const var_02: f32 = 0.001;
        const var_03: f64 = 0.0001;
        const var_04: f80 = 0.00001;
        const var_05: f128 = 0.000001;

        consume(.{ var_01, var_02, var_03, var_04, var_05 });
    }

    test "comptime_int型" {
        const var_01: comptime_int = 999_999;

        consume(.{var_01});
    }

    test "comptime_float型" {
        const var_01: comptime_float = 0.0000000009;

        consume(.{var_01});
    }

    test "bool型" {
        const var_01: bool = true;
        const var_02: bool = false;

        consume(.{ var_01, var_02 });
    }

    test "void型" {
        const var_01: void = void{};
        const var_02: void = {};

        consume(.{ var_01, var_02 });
    }

    test "noreturn型" {
        while (true) {
            const var_01: noreturn = {
                break;
            };

            consume(.{var_01});
        }
    }

    test "anyopaque型" {
        const var_01: u8 = 0;
        const var_02: *const anyopaque = @ptrCast(&var_01);

        consume(.{var_02});
    }

    test "anyerror型" {
        const var_01: anyerror = error.AnyError;

        consume(.{var_01});
    }

    test "C互換数値型" {
        const var_01: c_char = 10;
        const var_02: c_short = 20;
        const var_03: c_ushort = 30;
        const var_04: c_int = 40;
        const var_05: c_uint = 50;
        const var_06: c_long = 60;
        const var_07: c_ulong = 70;
        const var_08: c_longlong = 80;
        const var_09: c_ulonglong = 90;
        const var_10: c_longdouble = 10.5;

        consume(.{ var_01, var_02, var_03, var_04, var_05, var_06, var_07, var_08, var_09, var_10 });
    }
};

const arrays = struct {
    test "配列" {
        const var_01 = [3]i32{ 1, 2, 3 };
        const var_02 = [_]i32{ 1, 2, 3 }; // 要素数を省略する
        const var_03: [3]i32 = .{ 1, 2, 3 }; // 型を省略する

        consume(.{ var_01, var_02, var_03 });
    }

    test "番兵つき配列" {
        const var_01 = [3:0]i32{ 1, 2, 3 };
        const var_02 = [_:0]i32{ 1, 2, 3 }; // 要素数を省略する
        const var_03: [3:0]i32 = .{ 1, 2, 3 }; // 型を省略する

        consume(.{ var_01, var_02, var_03 });
    }
};

const vectors = struct {
    test "ベクトル型" {
        const var_01 = @Vector(4, i32){ 1, 2, 3, 4 }; // 整数型
        const var_02 = @Vector(4, f32){ 2.5, 3.5, 4.5, 5.5 }; // 浮動小数点数型

        var var_03: u32 = 0;
        const var_04 = @Vector(4, *u32){ &var_03, &var_03, &var_03, &var_03 }; // ポインタ型

        consume(.{ var_01, var_02, var_04 });
    }
};

const pointers = struct {
    test "単要素ポインタ" {
        var var_01: u32 = 45;
        const var_02: *u32 = &var_01;

        consume(.{var_02});
    }

    test "単要素定数ポインタ" {
        const var_01: u32 = 45;
        const var_02: *const u32 = &var_01;

        consume(.{var_02});
    }

    test "複数要素ポインタ" {
        var var_01: [3]u32 = .{ 45, 46, 47 };
        const var_02: [*]u32 = &var_01;

        consume(.{var_02});
    }

    test "複数要素定数ポインタ" {
        const var_01: [3]u32 = .{ 45, 46, 47 };
        const var_02: [*]const u32 = &var_01;

        consume(.{var_02});
    }

    test "番兵つき複数要素ポインタ" {
        var var_01: [3:0]u32 = .{ 45, 46, 47 };
        const var_02: [*:0]u32 = &var_01;

        consume(.{var_02});
    }

    test "番兵つき複数要素定数ポインタ" {
        const var_01: [3:0]u32 = .{ 45, 46, 47 };
        const var_02: [*:0]const u32 = &var_01;

        consume(.{var_02});
    }
};

const slice = struct {
    test "スライス型" {
        var var_01: [3]u32 = .{ 45, 46, 47 };
        const var_02: []u32 = &var_01;

        consume(.{var_02});
    }

    test "定数スライス型" {
        const var_01: [3]u32 = .{ 45, 46, 47 };
        const var_02: []const u32 = &var_01;

        consume(.{var_02});
    }

    test "番兵つきスライス型" {
        var var_01: [3:0]u32 = .{ 45, 46, 47 };
        const var_02: [:0]u32 = &var_01;

        consume(.{var_02});
    }

    test "番兵つき定数スライス型" {
        const var_01: [3:0]u32 = .{ 45, 46, 47 };
        const var_02: [:0]const u32 = &var_01;

        consume(.{var_02});
    }
};

const structs = struct {
    const Struct_01 = struct { x: u32, y: u32, z: u32 };
    const Struct_02 = struct { x: u32 = 16, y: u32, z: u32 };
    const Struct_03 = extern struct { x: u32, y: u32, z: u32 };
    const Struct_04 = packed struct { x: u32, y: u32, z: u32 };
    const Struct_05 = struct { u32, u32, u32 };

    test "構造体型" {
        const var_01 = Struct_01{ .x = 5, .y = 10, .z = 15 };
        const var_02: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };

        const var_03: Struct_02 = .{ .x = 5, .y = 10, .z = 15 };
        const var_04: Struct_02 = .{ .y = 10, .z = 15 }; // デフォルト値を使用する

        consume(.{ var_01, var_02, var_03, var_04 });
    }

    test "構造体型 C-ABIレイアウト" {
        const var_01: Struct_03 = .{ .x = 5, .y = 10, .z = 15 };

        consume(.{var_01});
    }

    test "構造体型 パックレイアウト" {
        const var_01: Struct_04 = .{ .x = 5, .y = 10, .z = 15 };

        consume(.{var_01});
    }

    test "構造体型 タプル" {
        const var_01: Struct_05 = .{ 5, 10, 15 };

        consume(.{var_01});
    }
};

const enums = struct {
    const Enum_01 = enum { first, second, third };
    const Enum_02 = enum(u8) { first = 1, second = 2, third = 3 };
    const Enum_03 = enum(u8) { first = 4, second, third };
    const Enum_04 = enum(u8) { first = 1, second = 2, third = 3, _ };

    test "列挙型" {
        const var_01 = Enum_01.first;
        const var_02: Enum_01 = .second;

        consume(.{ var_01, var_02 });
    }

    test "列挙型 数値型つき" {
        const var_01 = Enum_02.first;
        const var_02: Enum_02 = .second;

        const var_03 = Enum_03.first;
        const var_04: Enum_03 = .second;

        consume(.{ var_01, var_02, var_03, var_04 });
    }

    test "列挙型 非網羅的" {
        const var_01 = Enum_04.first;
        const var_02: Enum_04 = .second;
        const var_03: Enum_04 = @enumFromInt(0xff);

        consume(.{ var_01, var_02, var_03 });
    }
};

const unions = struct {
    const Enum_01 = enum { first, second, third };

    const Union_01 = union { int: i32, bool: bool, void: void };
    const Union_02 = union(Enum_01) { first: i32, second: bool, third: void };
    const Union_03 = union(enum) { first: i32, second: bool, third: void };
    const Union_04 = extern union { first: i32, second: bool, third: void };
    const Union_05 = packed union { first: i32, second: bool, third: void };

    test "合同型" {
        const var_01 = Union_01{ .int = 123456 };
        const var_02 = Union_01{ .bool = false };
        const var_03 = Union_01{ .void = void{} };

        consume(.{ var_01, var_02, var_03 });
    }

    test "合同型 タグ付き" {
        const var_01 = Union_02{ .first = 123456 };
        const var_02 = Union_02{ .second = false };
        const var_03 = Union_02{ .third = void{} };

        const var_04 = Union_03{ .first = 123456 };
        const var_05 = Union_03{ .second = false };
        const var_06 = Union_03{ .third = void{} };

        consume(.{ var_01, var_02, var_03, var_04, var_05, var_06 });
    }

    test "合同型 C-ABIレイアウト" {
        const var_01 = Union_04{ .first = 123456 };
        const var_02 = Union_04{ .second = false };
        const var_03 = Union_04{ .third = void{} };

        consume(.{ var_01, var_02, var_03 });
    }

    test "合同型 パックレイアウト" {
        const var_01 = Union_05{ .first = 123456 };
        const var_02 = Union_05{ .second = false };
        const var_03 = Union_05{ .third = void{} };

        consume(.{ var_01, var_02, var_03 });
    }
};

const opaques = struct {
    const Opaque_01 = opaque {};

    test "不透明型" {
        consume(.{Opaque_01});
    }
};

const optionals = struct {
    test "任意型" {
        const var_01: u8 = 5;
        const var_02: ?u8 = 5;
        const var_03: ?u8 = null;
        const var_04: ??u8 = 5;
        const var_05: u8 = var_04.?.?;

        consume(.{ var_01, var_02, var_03, var_04, var_05 });
    }
};

const errors = struct {
    test "エラー集合型" {
        const var_01: error{E} = error.E;
        const var_02: error{ E, R } = error.R;

        consume(.{ var_01, var_02 });
    }

    fn returnErrorUnion() !u8 {
        return 0;
    }

    test "エラー合同型" {
        const var_01: error{E}!u8 = 5;
        const var_02: error{E}!u8 = error.E;
        const var_03 = returnErrorUnion();

        consume(.{ var_01, var_02, var_03 });
    }
};
