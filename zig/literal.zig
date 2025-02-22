const utils = @import("./utils.zig");
const assert = utils.assert;
const equalSlices = utils.equalSlices;

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

/// 改行
const escape_sequence_01 = '\n';
/// キャリッジリターン
const escape_sequence_02 = '\r';
/// タブ文字
const escape_sequence_03 = '\t';
/// バックスラッシュ
const escape_sequence_04 = '\\';
/// シングルクオーテーション
const escape_sequence_05 = '\'';
/// ダブルクオーテーション
const escape_sequence_06 = '\"';
/// 16進数1バイト文字
const escape_sequence_07 = '\x64';
/// 16進数Unicodeコードポイント
const escape_sequence_08 = '\u{1F604}';

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

const enum_01 = .enum_literal;

const struct_01 = .{
    .foo = 1,
};
