//! # リテラル
//!
//! Zigのリテラルの書き方を確認する。
//!
//! ## 論理値リテラル
//!
//! - `true`または`false`がある。
//! - 論理値リテラルの型は`bool`。
//!
//! ## 整数リテラル
//!
//! - 10進数、2進数(0b)、8進数(0o)、16進数(0x)を使用できる。
//! - `_`(アンダースコア)で区切ることができる。
//! - 桁の上限はない。
//! - 整数リテラルの型は`comptime_int`。
//!
//! ## 浮動小数点数リテラル
//!
//! - 10進数、16進数(0x)を使用できる。
//! - 小数点、指数が使え、指数は10進数では`e`と`E`、16進数は`p`と`P`を使う。
//! - `_` で区切ることができる。
//! - 桁の上限はない。
//! - 小数リテラルの型は`comptime_float`。
//!
//! ## Unicodeコードポイントリテラル
//!
//! - シングルクォーテーション(')で囲われた文字をUnicodeコードポイントリテラルという。
//! - 1つのUnicodeコードポイントを表す。
//! - Unicodeコードポイントリテラルの型は`comptime_int`。
//! - エスケープシーケンスが使える。
//!
//! ## 文字列リテラル
//!
//! - ダブルクォーテーション(")で囲われた文字列を文字列リテラルという。
//! - 文字列リテラルではUnicodeコードポイントリテラルと同じエスケープシーケンスを使える。
//! - 文字列リテラルの型は`*const [N:0]u8`で、NはUTF-8で表わした時のバイト数。
//! - \\で始まる行は複数行文字列リテラルになる。
//! - 複数行文字列リテラルではエスケープシーケンスを使えない。
//! - 次の行も\\で始まる場合、改行文字を加えて連続した文字列として扱われる。
//!
//! ## 列挙型リテラル
//!
//! .(ドット)の後に識別子があると列挙型リテラルになる。
//!
//! ## 構造体型リテラル
//!
//! .の後に{}(波かっこ)があると構造体型リテラルになる。
//! 構造体型リテラルの中で、,(カンマ)区切りでフィールドを定義できる。
//! フィールドは`.<フィールド名> = <値>`のように書く。

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

// エスケープシーケンス
const escape_sequence_01 = '\n'; // 改行
const escape_sequence_02 = '\r'; // キャリッジリターン
const escape_sequence_03 = '\t'; // タブ
const escape_sequence_04 = '\\'; // バックスラッシュ
const escape_sequence_05 = '\''; // 単引用符
const escape_sequence_06 = '\"'; // 二重引用符
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

test "列挙型リテラル" {
    _ = .enum_literal;
}

test "構造体型リテラル" {
    _ = .{
        .foo = 1,
    };
}
