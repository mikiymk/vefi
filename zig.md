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

### \*

### \*%

### \*|

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

### .\*

### ++

### \*\*

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
