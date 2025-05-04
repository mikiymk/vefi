# 配列

- 配列は同じ型の複数の値を持つコレクション型。
- 一つの数値のインデックスで要素にアクセスできる。
- std::vector (C++)
- java.util.ArrayList (Java)

## 配列の機能

### get

- インデックスを指定して、そのインデックスに関連付けられた値を得る。
- std::vector::operator[] (C++)
- std::vector::at (C++)

### set

- インデックスを指定して、そのインデックスに値を関連付ける。
- もし既にインデックスに値が関連付けられていた場合、値を上書きする。

### size

- 有効なインデックスの数を得る。
- 通常、有効なインデックスは`0`から`size - 1`まで。

### reverse

- 現在のインデックスの順番から、逆順にインデックスを付け直す。

### indexOf

### sort

### pushFront

### pushBack

### popFront

### popBack

### clear

### concat

### slice

## 配列の種類

### 静的と動的

### 線形と循環
