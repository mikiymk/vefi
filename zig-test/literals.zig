//! Zigのリテラルの書き方を確認する。

const utils = @import("./utils.zig");
const assert = utils.assert;

test {
    _ = integer;
}

/// # 整数リテラル
///
/// - 10進数、2進数(0b)、8進数(0o)、16進数(0x)を使用できる。
/// - `_`(アンダースコア)で区切ることができる。
/// - 整数リテラルの型は`comptime_int`で、桁の上限はない。
pub const integer = struct {
    pub const value_1 = 42;
    pub const value_2 = 1_000_999;
    pub const value_3 = 12345678_12345678_12345678_12345678_12345678_12345678_12345678_12345678;
    pub const value_4 = 0b0110;
    pub const value_5 = 0o704;
    pub const value_6 = 0x1f2e;
    pub const value_7 = 0x1F2e;

    test "整数リテラルの型" {
        try assert(@TypeOf(42) == comptime_int);
    }
};

test "小数リテラル" {
    // 10進数、16進数(0x)を使用できる。
    // 小数点、指数が使え、指数は10進数ではeとE、16進数はpとPを使う。
    // `_` で区切ることができる。
    // 小数リテラルの型は`comptime_float`で、桁の上限はない。

    _ = 12.3;
    _ = 12e4;
    _ = 12E4;
    _ = 12e-5;
    _ = 12.3e4;

    // リテラルは上限がない
    _ = 3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647;

    // _で区切ることができる
    _ = 3.1415_9265;

    // 16進数
    _ = 0x1f2e.3d4c;
    _ = 0x123abcP10;

    try assert(@TypeOf(12.3e4) == comptime_float);
}

test "Unicodeコードポイントリテラル" {
    // シングルクォーテーション(')で囲われた文字をUnicodeコードポイントリテラルという。
    // 1つのUnicodeコードポイントを表す。
    // Unicodeコードポイントリテラルの型は`comptime_int`。
    // エスケープシーケンスが使える。

    _ = 'a';
    _ = '😃'; // ascii外の文字

    // エスケープシーケンス
    _ = '\n'; // 改行
    _ = '\r'; // キャリッジリターン
    _ = '\t'; // タブ
    _ = '\\'; // バックスラッシュ
    _ = '\''; // 単引用符
    _ = '\"'; // 二重引用符
    _ = '\x64'; // 16進数1バイト文字
    _ = '\u{1F604}'; // 16進数Unicodeコードポイント

    try assert(@TypeOf('a') == comptime_int);
}

test "文字列リテラル" {
    // ダブルクォーテーション(")で囲われた文字列を文字列リテラルという。
    // 文字列リテラルではUnicodeコードポイントリテラルと同じエスケープシーケンスを使える。
    // 文字列リテラルの型は`*const [N:0]u8`で、NはUTF-8で表わした時のバイト数。

    _ = "abc";

    // エスケープシーケンス
    _ = "dog\r\nwolf";

    try assert(@TypeOf("abc") == *const [3:0]u8);

    // \\で始まる行は複数行文字列リテラルになる。
    // 複数行文字列リテラルではエスケープシーケンスを使えない。
    // 次の行も\\で始まる場合、改行文字を加えて連続した文字列として扱われる。
    _ =
        \\abc
        \\def
        \\ghi\t
    ;
}

test "列挙型リテラル" {
    // .(ドット)の後に識別子があると列挙型リテラルになる。

    _ = .enum_literal;
}

test "構造体型リテラル" {
    // .の後に{}(波かっこ)があると構造体型リテラルになる。
    // 構造体型リテラルの中で、,(カンマ)区切りでフィールドを定義できる。
    // フィールドは`.<フィールド名> = <値>`のように書く。

    _ = .{
        .foo = 1,
    };
}
