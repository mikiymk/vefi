# Zig

Zig の書き方について

## キーワード

```zig
addrspace
align
allowzero
and
anyframe
anytype
asm
async
await
break
callconv
catch
comptime
const
continue
defer
else
enum
errdefer
error
export
extern
fn
for
if
inline
linksection
noalias
noinline
nosuspend
opaque
or
orelse
packed
pub
resume
return
struct
suspend
switch
test
threadlocal
try
union
unreachable
usingnamespace
var
volatile
while


```

## リテラル

ソースコード上で値を表したもの

### 論理値リテラル

`true`と`false`がある。

```zig
const v1 = true;
const v2 = false;
```

### 整数リテラル

10 進数、2 進数、8 進数、16 進数が使える。
区切り文字として`_`(アンダースコア)を使用できる。

```zig
const v1 = 42;
const v2 = 0b11110000;
const v3 = 0o12345670;
const v4 = 0x1234ABCD;
const v5 = 1234_5678;
```

### 浮動小数点数リテラル

10 進数、16 進数が使える。
区切り文字として`_`(アンダースコア)を使用できる。

```zig
const v1 = 1.23e+45;
const v2 = 0x1.abP-12;
const v3 = 1.234_567e89;
```

### Unicode コードポイントリテラル

1 つの Unicode コードポイントを表す`'`(シングルクオーテーション)で囲われた 1 文字。
エスケープシーケンスは改行(`\n`)、キャリッジリターン(`\r`)、タブ文字(`\t`)、バックスラッシュ(`\\`)、シングルクオーテーション(`\'`)、ダブルクオーテーション(`\"`)、16 進数のコードポイント指定文字(`\xNN`、`\u{NNNNNN}`)が使える。

```zig
const v1 = 'a';
const v2 = 'あ';
const v3 = '\u{10FFFF}';
```

### 文字列リテラル

`"`(ダブルクオーテーション)で囲われた 1 行文字列と`\\`(バックスラッシュ 2 つ)で始まる連続した行の複数行文字列がある。
UTF-8 エンコードされたバイト列として扱われる。

```zig
const v1 = "The fox jumps over the lazy dog.";
const v2 = "abcd\nefgh\nijkl\nmnop";
const v3 =
    \\abcd
    \\efgh
    \\ijkl
    \\mnop
;
```

### 列挙型リテラル

`AnyEnum.enu_value`
型名は省略できる。

```zig
const v1 = AnyEnum.value_1;
const v2: AnyEnum = .value_2;
```

### 構造体リテラル

型名は省略して`.`にできる。

```zig
const s1 = AnyStruct{ .foo = 1 };
const s2: AnyStruct = .{ .foo = 1 };
```

### その他のリテラル

オプション型の`null`、代入文で使用できる`undefined`がある。

## 型

データを表すもの

### 整数型

符号なし整数の`u`と符号付き整数の`i`の後ろにビット数をつけた型。
ビット数は0から65535までの整数を指定できる。
ポインターサイズの`usize`と`isize`がある。

```zig
const v1 = u8;
const v2 = i64;
const v3 = u0;
const v4 = i65535;
```

### 浮動小数点数型

`f`の後ろにビット数をつけた型。
ビット数は16、32、64、80、128を指定できる。

```zig
const v1 = f16;
const v2 = f32;
const v3 = f64;
const v4 = f80;
const v5 = f128;
```

### 論理型

真偽値を表す。

```zig
const v1 = bool;
```

### 配列型

ひとつの型を並べた型。
配列の長さと値の型を指定できる。
型の初期化式につける場合は長さを省略できる。
番兵を指定できる。

```zig
const v1 = [5]u8;
const v2 = [_]u8{0, 1, 2, 3, 4};
const v3 = [5:0]u8;
```

### ベクトル型

整数型、浮動小数点数型、ポインター型を並べた型。
ベクトル型の元になった型と同じ演算子を使用できる。
SIMD命令に使われる。

```zig
const v1 = @Vector(4, u8);
const v2 = @Vector(4, f32);
const v3 = @Vector(4, *i32);
```

### 構造体型

複数の値をまとめた型。
0個以上のフィールド名と型のペアを持つ。

```zig
const v1 = struct {
    id: u32,
    name: []const u8,
};
```

`extern struct`はC ABIとの互換性がある。
`packed struct`はメモリ内レイアウトが保証される。

### タプル型

複数の値をまとめた型。
構造体と違い、フィールド名を持たない。

```zig
const v1 = struct { u8, i32, f64 };
```

### 列挙型

識別子の集合を表す型。

```zig
const v1 = enum { value_1, value_2 };
```

整数のタグ型を指定できる。

```zig
const v2 = enum(u1) { value_1, value_2 };
```

タグ型がある場合、順序値を指定できる。

```zig
const v3 = enum(u2) { value_1 = 1, value_2 = 2 };
```

非網羅的な列挙型。

```zig
const v4 = enum(u8) { value_1, value_2, _ };
```

### 合併型

複数の型のどれか一つを表す型。

```zig
const v1 = union {
    value_1: u8,
    value_2: i32,
};
```

列挙型のタグを付けることができる。

```zig
const v2 = union(Enum1) {
    value_1: u8,
    value_2: i32,
};
```

推論されたタグ型。

```zig
const v3 = union(enum) {
    value_1: u8,
    value_2: i32,
};
```



`extern union`はC ABIとの互換性がある。
`packed union`はメモリ内レイアウトが保証される。

### ポインター型

### スライス型

### オプション型

### エラー集合型

### エラー合併型

### 関数型

### 型型

### その他の型

- comptime_int
- comptime_float
- void
- noreturn
- anyopaque

## 演算子

値の計算をするもの

### +
### +%
### +|
### -
### -%
### -|
### *
### *%
### *|
### /
### %
### - (単項前置)
### -% (単項前置)
### <<
### <<|
### >>
### &
### |
### ^
### ~ (単項前置)
### and
### or
### !
### ==
### !=
### >
### >=
### <
### <=
### .*
### ++
### **
### orelse
### .?
### catch
### a()
### a[i]
### a[i..j]
### a.b
### a.b()
### & (単項前置)
### =
### a{}
### ||
### ()
### {}
### comptime

## 制御式

### 宣言文
### ブロック文
### if文
### switch文
### for文
### while文
### defer文
### try文
### errdefer文
### return文
### unreachable文
### asm文

## 組み込み関数

## 型変換
