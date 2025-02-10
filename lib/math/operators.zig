//! 演算子の関数

pub fn add(a: anytype, b: @TypeOf(a)) @@TypeOf(a) {
    return a + b;
}

