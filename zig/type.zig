const utils = @import("./utils.zig");
const consume = utils.consume;
const assert = utils.assert;

const Struct_01 = struct { x: u32, y: u32, z: u32 };
const Struct_02 = struct { x: u32 = 16, y: u32, z: u32 };
const Struct_03 = extern struct { x: u32, y: u32, z: u32 };
const Struct_04 = packed struct { x: u32, y: u32, z: u32 };

const Tuple_01 = struct { u32, u32, u32 };
const Tuple_02 = struct { u32, u32, u32 = 0 };

const Enum_01 = enum { first, second, third };
const Enum_02 = enum(u8) { first = 1, second = 2, third = 3 };
const Enum_03 = enum(u8) { first = 4, second, third };
const Enum_04 = enum(u8) { first = 1, second = 2, third = 3, _ };

const Union_01 = union { first: i32, second: bool, third: void };
const Union_02 = union(Enum_01) { first: i32, second: bool, third: void };
const Union_03 = union(enum) { first: i32, second: bool, third: void };
const Union_04 = extern union { first: i32, second: bool, third: void };
const Union_05 = packed union { first: i32, second: bool, third: void };

const Opaque_01 = opaque {};

const ErrorSet_01 = error{ E, R };

const ErrorUnion_01 = ErrorSet_01!u8;

var var_01: u32 = 8;
var var_02: [3:0]u32 = .{ 1, 2, 3 };

test "整数型" {
    const integer_01: u32 = 50;
    const integer_02: i32 = -300;
    const integer_03: u0 = 0;
    const integer_04: i65535 = -9999;

    consume(integer_01);
    consume(integer_02);
    consume(integer_03);
    consume(integer_04);
}

test "浮動小数点型" {
    const float_01: f16 = 0.01;
    const float_02: f32 = 0.001;
    const float_03: f64 = 0.0001;
    const float_04: f80 = 0.00001;
    const float_05: f128 = 0.000001;

    consume(float_01);
    consume(float_02);
    consume(float_03);
    consume(float_04);
    consume(float_05);
}

test "コンパイル時整数型" {
    const comptime_int_01: comptime_int = 999_999;

    consume(comptime_int_01);
}

test "コンパイル時浮動小数点型" {
    const comptime_float_01: comptime_float = 0.0000000009;

    consume(comptime_float_01);
}

test "論理型" {
    const bool_01: bool = true;
    const bool_02: bool = false;

    consume(bool_01);
    consume(bool_02);
}

test "void型" {
    const void_01: void = void{};
    const void_02: void = {};

    consume(void_01);
    consume(void_02);
}

test "noreturn型" {
    while (true) {
        const noreturn_01: noreturn = {
            break;
        };

        consume(noreturn_01);
    }
}

fn anytype_01(a: anytype) void {
    _ = a;
}

test "anytype型" {
    anytype_01(@as(u8, 1));
    anytype_01(@as(f32, 3.14));
    anytype_01(@as([]const u8, "hello"));
}

test "anyopaque型" {
    const anyopaque_01: *anyopaque = @ptrCast(&var_01);
    const anyopaque_02: *const anyopaque = @ptrCast(&var_01);

    consume(anyopaque_01);
    consume(anyopaque_02);
}

test "anyerror型" {
    const anyerror_01: anyerror = error.AnyError;

    consume(anyerror_01);
}

test "C-ABI互換型" {
    const c_compatible_01: c_char = 10;
    const c_compatible_02: c_short = 20;
    const c_compatible_03: c_ushort = 30;
    const c_compatible_04: c_int = 40;
    const c_compatible_05: c_uint = 50;
    const c_compatible_06: c_long = 60;
    const c_compatible_07: c_ulong = 70;
    const c_compatible_08: c_longlong = 80;
    const c_compatible_09: c_ulonglong = 90;
    const c_compatible_10: c_longdouble = 10.5;

    consume(c_compatible_01);
    consume(c_compatible_02);
    consume(c_compatible_03);
    consume(c_compatible_04);
    consume(c_compatible_05);
    consume(c_compatible_06);
    consume(c_compatible_07);
    consume(c_compatible_08);
    consume(c_compatible_09);
    consume(c_compatible_10);
}

test "配列型" {
    const array_01 = [3]u32{ 1, 2, 3 };
    const array_02 = [_]u32{ 1, 2, 3 }; // 要素数を省略する
    const array_03: [3]u32 = .{ 1, 2, 3 }; // 型を省略する
    const array_04 = [3:0]u32{ 1, 2, 3 }; // 番兵付き配列

    consume(array_01);
    consume(array_02);
    consume(array_03);
    consume(array_04);
}

test "ベクトル型" {
    const vectors_01 = @Vector(4, bool){ true, false, true, false }; // 論理値型
    const vectors_02 = @Vector(4, u32){ 1, 2, 3, 4 }; // 整数型
    const vectors_03 = @Vector(4, f32){ 2.5, 3.5, 4.5, 5.5 }; // 浮動小数点数型
    const vectors_04 = @Vector(4, *u32){ &var_01, &var_01, &var_01, &var_01 }; // ポインタ型

    consume(vectors_01);
    consume(vectors_02);
    consume(vectors_03);
    consume(vectors_04);
}

test "単要素ポインター型" {
    const single_item_pointer_01: *u32 = &var_01;
    const single_item_pointer_02: *const u32 = &var_01;
    const single_item_pointer_03: *volatile u32 = &var_01;
    const single_item_pointer_04: *align(32) u32 = @alignCast(&var_01);
    const single_item_pointer_05: *allowzero u32 = &var_01;
    const single_item_pointer_06: *allowzero align(32) const volatile u32 = @alignCast(&var_01);

    consume(single_item_pointer_01);
    consume(single_item_pointer_02);
    consume(single_item_pointer_03);
    consume(single_item_pointer_04);
    consume(single_item_pointer_05);
    consume(single_item_pointer_06);
}

test "複数要素ポインター型" {
    const many_item_pointer_01: [*]u32 = &var_02;
    const many_item_pointer_02: [*:0]u32 = &var_02;

    consume(many_item_pointer_01);
    consume(many_item_pointer_02);
}

test "Cポインター型" {
    const c_pointer_01: [*c]u32 = &var_01;
    const c_pointer_02: [*c]u32 = &var_02;

    consume(c_pointer_01);
    consume(c_pointer_02);
}

test "スライス型" {
    const slice_01: []u32 = &var_02;
    const slice_02: [:0]u32 = &var_02;

    consume(slice_01);
    consume(slice_02);
}

test "構造体型" {
    const struct_01 = Struct_01{ .x = 5, .y = 10, .z = 15 }; // 構造体。
    const struct_02: Struct_01 = .{ .x = 5, .y = 10, .z = 15 }; // 型を省略する。
    const struct_03: Struct_02 = .{ .y = 10, .z = 15 }; // フィールドを省略してデフォルト値を使用する。
    const struct_04: Struct_03 = .{ .x = 5, .y = 10, .z = 15 }; // C言語のABIと互換性のある構造体。
    const struct_05: Struct_04 = .{ .x = 5, .y = 10, .z = 15 }; // メモリレイアウトが保証される構造体。

    consume(struct_01);
    consume(struct_02);
    consume(struct_03);
    consume(struct_04);
    consume(struct_05);
}

test "タプル型" {
    const tuple_01 = Tuple_01{ 5, 10, 15 };
    const tuple_02: Tuple_01 = .{ 5, 10, 15 };
    const tuple_03: Tuple_02 = .{ 5, 10 };

    consume(tuple_01);
    consume(tuple_02);
    consume(tuple_03);
}

test "列挙型" {
    const enum_01 = Enum_01.first;
    const enum_02: Enum_01 = .second;
    const enum_03: Enum_02 = .second;
    const enum_04: Enum_03 = .second;
    const enum_05: Enum_04 = .second;
    const enum_06: Enum_04 = @enumFromInt(99);

    try assert(@intFromEnum(enum_03) == 2);
    try assert(@intFromEnum(enum_04) == 5);
    try assert(@intFromEnum(enum_05) == 2);
    try assert(@intFromEnum(enum_06) == 99);

    consume(enum_01);
    consume(enum_02);
    consume(enum_03);
    consume(enum_04);
    consume(enum_05);
    consume(enum_06);
}

test "共用体型" {
    const union_01 = Union_01{ .second = false };
    const union_02: Union_01 = .{ .third = void{} };
    const union_03: Union_02 = .{ .first = 123456 };
    const union_04: Union_03 = .{ .first = 123456 };
    const union_05: Union_04 = .{ .first = 123456 };
    const union_06: Union_05 = .{ .first = 123456 };

    consume(union_01);
    consume(union_02);
    consume(union_03);
    consume(union_04);
    consume(union_05);
    consume(union_06);
}

test "不透明型" {
    // const opaque_01: Opaque_01 = undefined;
    const opaque_02: *Opaque_01 = undefined;

    consume(opaque_02);
}

fn returnError() !u8 {
    return error.R;
}

test "エラー型" {
    const error_set_01 = ErrorSet_01.E;
    const error_set_02: ErrorSet_01 = error.R;

    consume(error_set_01);
    consume(error_set_02);

    const error_union_01: ErrorUnion_01 = 5;
    const error_union_02: ErrorUnion_01 = error.E;
    const error_union_03 = returnError();

    consume(error_union_01);
    consume(error_union_02);
    consume(error_union_03);
}

test "オプション型" {
    const optional_01: ?u8 = 5;
    const optional_02: ?u8 = null;

    consume(optional_01);
    consume(optional_02);
}

fn add(a: u32, b: u32) u32 {
    return a + b;
}

test "関数型" {
    const function_01: fn (u32, u32) u32 = add;
    const function_02: *const fn (u32, u32) u32 = add;

    consume(function_01);
    consume(function_02);
}

test "型型" {
    const type_01: type = u8;
    const type_02: type = type;

    consume(type_01);
    consume(type_02);
}

test "型のアラインメント" {
    // 型のアラインメント
    const align_01: u8 align(128) = 1;

    // ポインターのアラインメント
    const align_02: *align(128) u8 = @constCast(&align_01);

    // ポインターのアラインメントと型のアラインメントの組み合わせ
    const align_03: *align(8) u32 align(4) = @alignCast(&var_01);

    // ビット単位のアラインメント
    const pointer_alignment = 1;
    const pointer_bit_offset = 3;
    const pointer_host_size = 1;
    const align_04: *align(pointer_alignment:pointer_bit_offset:pointer_host_size) u3 = undefined;

    consume(align_01);
    consume(align_02);
    consume(align_03);
    consume(align_04);
}
