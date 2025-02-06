const utils = @import("./utils.zig");
const consume = utils.consume;
const assert = utils.assert;

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

/// 基本型。
/// 複合型ではない型。
const primitive_types = struct {
    /// ビットサイズは0から65535ビットまであり、符号付き(`i`)、符号なし(`u`)の2種類がある。
    /// ポインタサイズの`usize`と`isize`がある。
    const integer = struct {
        const value_01: u8 = 50;
        const value_02: i32 = -300;
        const value_03: u0 = 0;
        const value_04: i65535 = -9999;
    };

    /// 半精度(16ビット)、単精度(32ビット)、倍精度(64ビット)、拡張倍精度(80ビット)、四倍精度(128ビット)の浮動小数点数型がある。
    const float = struct {
        const value_01: f16 = 0.01;
        const value_02: f32 = 0.001;
        const value_03: f64 = 0.0001;
        const value_04: f80 = 0.00001;
        const value_05: f128 = 0.000001;
    };

    const value_01: comptime_int = 999_999;

    const value_02: comptime_float = 0.0000000009;

    const value_03: bool = true;
    const value_04: bool = false;

    const value_05: void = void{};
    const value_06: void = {};

    const value_07: noreturn = {};

    const value_08_1: u8 = 0;
    const value_08_2: *const anyopaque = @ptrCast(&value_08_1);

    const value_09: anyerror = error.AnyError;

    const c_compatible = struct {
        const value_01: c_char = 10;
        const value_02: c_short = 20;
        const value_03: c_ushort = 30;
        const value_04: c_int = 40;
        const value_05: c_uint = 50;
        const value_06: c_long = 60;
        const value_07: c_ulong = 70;
        const value_08: c_longlong = 80;
        const value_09: c_ulonglong = 90;
        const value_10: c_longdouble = 10.5;
    };
};

const arrays = struct {
    const value_01 = [3]i32{ 1, 2, 3 };
    /// 要素数を省略する
    const value_02 = [_]i32{ 1, 2, 3 };
    /// 型を省略する
    const value_03: [3]i32 = .{ 1, 2, 3 };
    /// 番兵付き配列
    const value_04 = [3:0]i32{ 1, 2, 3 };
};

const vectors = struct {
    /// 整数型
    const value_01 = @Vector(4, i32){ 1, 2, 3, 4 };
    /// 浮動小数点数型
    const value_02 = @Vector(4, f32){ 2.5, 3.5, 4.5, 5.5 };
    /// ポインタ型
    var value_03_1: u32 = 0;
    const value_03_2 = @Vector(4, *u32){ &value_03_1, &value_03_1, &value_03_1, &value_03_1 };
    /// 論理値型
    const value_04 = @Vector(4, bool){ true, false, true, false };
};

const pointers = struct {
    var var_01: u32 = 42;
    var var_02: [3:0]u32 = .{ 45, 46, 47 };

    const value_01: *u32 = &var_01;
    const value_02: *const u32 = &var_01;

    const value_03: [*]u32 = &var_02;
    const value_04: [*]const u32 = &var_02;
    const value_05: [*:0]u32 = &var_02;
    const value_06: [*:0]const u32 = &var_02;
};

const slice = struct {
    var var_01: [3:0]u32 = .{ 45, 46, 47 };

    const value_01: []u32 = &var_01;
    const value_02: []const u32 = &var_01;
    const value_03: [:0]u32 = &var_01;
    const value_04: [:0]const u32 = &var_01;
};

const structs = struct {
    const Struct_01 = struct { x: u32, y: u32, z: u32 };
    const Struct_02 = struct { x: u32 = 16, y: u32, z: u32 };
    const Struct_03 = extern struct { x: u32, y: u32, z: u32 };
    const Struct_04 = packed struct { x: u32, y: u32, z: u32 };
    const Struct_05 = struct { u32, u32, u32 };

    /// 構造体。
    const value_01 = Struct_01{ .x = 5, .y = 10, .z = 15 };

    /// 型を省略する。
    const value_02: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };

    /// フィールドを省略してデフォルト値を使用する。
    const value_03: Struct_02 = .{ .y = 10, .z = 15 };

    /// C言語のABIと互換性のある構造体。
    const value_04: Struct_03 = .{ .x = 5, .y = 10, .z = 15 };

    /// メモリレイアウトが保証される構造体。
    const value_05: Struct_04 = .{ .x = 5, .y = 10, .z = 15 };

    /// タプル。
    const value_06: Struct_05 = .{ 5, 10, 15 };
};

const enums = struct {
    const Enum_01 = enum { first, second, third };
    const Enum_02 = enum(u8) { first = 1, second = 2, third = 3 };
    const Enum_03 = enum(u8) { first = 4, second, third };
    const Enum_04 = enum(u8) { first = 1, second = 2, third = 3, _ };

    const value_01 = Enum_01.first;
    const value_02: Enum_01 = .second;
    const value_03: Enum_02 = .second;
    const value_04: Enum_03 = .second;
    const value_05: Enum_04 = .second;
    const value_06: Enum_04 = @enumFromInt(99);

    test "列挙型から整数へ変換" {
        try assert(@intFromEnum(value_03) == 2);
        try assert(@intFromEnum(value_04) == 5);
        try assert(@intFromEnum(value_05) == 2);
        try assert(@intFromEnum(value_06) == 99);
    }
};

const unions = struct {
    const Enum_01 = enum { first, second, third };

    const Union_01 = union { int: i32, bool: bool, void: void };
    const Union_02 = union(Enum_01) { first: i32, second: bool, third: void };
    const Union_03 = union(enum) { first: i32, second: bool, third: void };
    const Union_04 = extern union { first: i32, second: bool, third: void };
    const Union_05 = packed union { first: i32, second: bool, third: void };

    const value_02 = Union_01{ .bool = false };
    const value_03: Union_01 = .{ .void = void{} };
    const value_04: Union_02 = .{ .first = 123456 };
    const value_05: Union_03 = .{ .first = 123456 };
    const value_06: Union_04 = .{ .first = 123456 };
    const value_07: Union_05 = .{ .first = 123456 };
};

const opaques = struct {
    const Opaque_01 = opaque {};
};

const optionals = struct {
    const value_01: ?u8 = 5;
    const value_02: ?u8 = null;
};

const errors = struct {
    const Error_01 = error{ E, R };
    const ErrorUnion_01 = Error_01!u8;

    fn returnError() !u8 {
        return error.R;
    }

    const value_01 = Error_01.E;
    const value_02: Error_01 = error.R;
    const value_03: ErrorUnion_01 = 5;
    const value_04: ErrorUnion_01 = error.E;
    const value_05 = returnError();
};
