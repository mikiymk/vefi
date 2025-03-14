const utils = @import("./utils.zig");
const assert = utils.assert;
const equalSlices = utils.equalSlices;

const compileZig = utils.compileZig;

test "nullリテラル" {
    try assert(try compileZig("const foo: ?u8 = null;") == .success);
    try assert(try compileZig("const foo = null;") == .success);
    try assert(@TypeOf(null) == @TypeOf(null));
}

const boolean_01 = true;
const boolean_02 = false;

test "論理値リテラルの型" {
    try assert(@TypeOf(true) == bool);
}

pub const integer_01 = 42;
pub const integer_02 = 1_000_999;
pub const integer_03 = 12345678_12345678_12345678_12345678_12345678_12345678_12345678_12345678;
pub const integer_04 = 0b0110;
pub const integer_05 = 0o704;
pub const integer_06 = 0x1f2e;
pub const integer_07 = 0x1F2e;

test "整数リテラルの型" {
    try assert(@TypeOf(42) == comptime_int);
}

const float_01 = 12.3;
const float_02 = 12e4;
const float_03 = 12E4;
const float_04 = 12e-5;
const float_05 = 12.3e4;
const float_06 = 3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647;
const float_07 = 3.1415_9265;
const float_08 = 0x1f2e.3d4c;
const float_09 = 0x123abcP10;

test "小数リテラルの型" {
    try assert(@TypeOf(12.3e4) == comptime_float);
}

test "違う表記の同じ小数" {
    try assert(12.3e4 == 123000.0);
}

const unicode_01 = 'a';
const unicode_02 = '😃'; // ascii外の文字

const escape_sequence_01 = '\n'; // 改行
const escape_sequence_02 = '\r'; // キャリッジリターン
const escape_sequence_03 = '\t'; // タブ文字
const escape_sequence_04 = '\\'; // バックスラッシュ
const escape_sequence_05 = '\''; // シングルクオーテーション
const escape_sequence_06 = '\"'; // ダブルクオーテーション
const escape_sequence_07 = '\x64'; // 16進数1バイト文字
const escape_sequence_08 = '\u{1F604}'; // 16進数Unicodeコードポイント

test "Unicodeコードポイントリテラルの型" {
    try assert(@TypeOf('a') == comptime_int);
}

const string_01 = "abc";
const string_02 = "dog\tcat";
const string_03 =
    \\abc
    \\def
    \\ghi
;
const string_04 = "abc\ndef\n\\t";
const string_05 =
    \\abc
    \\def
    \\\t
;

test "文字列リテラルの型" {
    try assert(@TypeOf("abc") == *const [3:0]u8);
}

test "複数行文字列リテラル" {
    try assert(equalSlices(string_04, string_05));
}

const Enum_01 = enum { value_1, value_2 };

const enum_01 = Enum_01.value_1;
const enum_02: Enum_01 = .value_2;
const enum_03 = .value_3;

test "列挙型リテラルの型" {
    try assert(@TypeOf(.value_3) == @TypeOf(.enum_literal));
}

const Struct_01 = struct { value: i32 };

const struct_01 = Struct_01{ .value = 1 };
const struct_02: Struct_01 = .{ .value = 1 };
const struct_03 = .{ .value = 1 };

test "構造体リテラルの型" {
    try assert(@TypeOf(.{ .value = 1 }) != @TypeOf(.{ .value = 1 }));
    try assert(@TypeOf(.{ .value = 1 }) != @TypeOf(.{ .value_2 = 1 }));
}

const error_01 = error.Error_01;

test "エラーリテラルの型" {
    try assert(@TypeOf(error.Error_01) == error{Error_01});
}

const undefined_01: u8 = undefined;
const undefined_02 = undefined;

test "undefinedリテラルの型" {
    try assert(@TypeOf(undefined) == @TypeOf(undefined));
}
