//! lib.zig_test
//!
//! Zig言語の基本の書き方を確認する。

test "整数リテラル 10進数" {
    _ = 42; // 10進数の整数
    _ = 1234567812345678123456781234567812345678123456781234567812345678; // リテラルは上限がない
    _ = 1_000_999; // _で区切ることができる

    assert.expectEqual(@TypeOf(42), comptime_int);
}
test "整数リテラル 2進数" {
    _ = 0b0110; // "0b" で始めると2進数
    _ = 0b_1100_0011; // _で区切ることができる
}
test "整数リテラル 8進数" {
    _ = 0o704; // "0o" で始めると8進数
    _ = 0o_567_123; // _で区切ることができる
}
test "整数リテラル 16進数" {
    _ = 0x1f2e; // "0x" で始めると16進数
    _ = 0x1F2E; // 大文字も使用できる
    _ = 0x_abcd_ABCD; // _で区切ることができる
}

test "小数リテラル 10進数" {
    _ = 42.1; // 小数点付き数
    _ = 42e5; // 指数付き数
    _ = 42E5; // 大文字の指数付き数
    _ = 42e-5; // 負の指数付き数
    _ = 42.2e5; // 小数点と指数付き数
    _ = 3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647; // リテラルは上限がない
    _ = 3.1415_9265; // _で区切ることができる

    assert.expectEqual(@TypeOf(42.5), comptime_float);
}
test "小数リテラル 16進数" {
    _ = 0x1f2e.3d4c; // "0x" で始めると16進数
    _ = 0abcp10; // pで指数を区切る
    _ = 0x1a_2bP-3; // _で区切ることができる
}

test "文字リテラル" {
    _ = 'a'; // ''で囲うと文字リテラル
    _ = '😃'; // 1つのUnicodeコードポイントを表す

    _ = '\n'; // 改行
    _ = '\r'; // キャリッジリターン
    _ = '\t'; // タブ
    _ = '\\'; // バックスラッシュ
    _ = '\''; // 単引用符
    _ = '\"'; // 二重引用符
    _ = '\x64'; // 1バイト文字
    _ = '\u{1F604}'; // Unicodeコードポイント

    assert.expectEqual(@TypeOf('a'), comptime_int);
}
test "文字列リテラル" {
    _ = "abc"; // ""で囲うと文字列リテラル
    _ = "dog\r\nwolf"; // エスケープシーケンス

    // ゼロ終端バイト列の定数ポインタ
    assert.expectEqual(@TypeOf("abc"), *const [3:0]u8);
}
test "文字列リテラル 複数行" {
    // \\から後ろは複数行文字列リテラル
    _ =
        \\abc
        \\def
    ;
    // エスケープシーケンス
    _ =
        \\a\tbc
    ;
}

test "整数型" {
    // 8の倍数の整数型
    const var1: u8 = 50;
    const var2: u16 = 500;
    const var2: u32 = 5000;
    const var2: u64 = 50000;
    const var2: u128 = 500000;
    const var1: i8 = -50;
    const var2: i16 = -500;
    const var2: i32 = -5000;
    const var2: i64 = -50000;
    const var2: i128 = -500000;

    // 任意幅の整数型
    const var2: u0 = 0;
    const var2: i65535 = -40;
}

test "浮動小数点数型" {
    const var1: f16 = 0.01;
    const var1: f32 = 0.001;
    const var1: f64 = 0.0001;
    const var1: f80 = 0.00001;
    const var1: f128 = 0.000001;
}

test "comptime_int" {
    const var1: comptime_int = 999_999;
}

test "comptime_float" {
    const var1: comptime_float = 0.0000000009;
}

test "bool" {
    const var1: bool = true;
    const var1: bool = false;
}

test "void" {
    const var1: void = void{};
}

test "C互換数値型" {}

test "配列" {}
test "配列 番兵つき" {}

test "ベクトル型" {}

test "ポインタ型 単要素ポインタ" {}
test "ポインタ型 複数要素ポインタ" {}

test "スライス型" {}

test "構造体型" {}

test "列挙型" {}
test "合同型" {}

test "不透明型" {}

test "ブロック文" {}
test "if文" {}
test "switch文" {}
test "for文" {}
test "while文" {}
test "defer文" {}

test "演算子 +" {}

test "組み込み関数 @TypeOf" {}