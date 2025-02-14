//! 演算子の関数

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a + b;
}

pub fn addWrap(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a +% b;
}

pub fn addSaturate(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a +| b;
}

pub fn sub(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a - b;
}

pub fn subWrap(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a -% b;
}

pub fn subSaturate(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a -| b;
}

pub fn mul(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a * b;
}

pub fn mulWrap(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a *% b;
}

pub fn mulSaturate(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a *| b;
}

pub fn div(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a / b;
}

pub fn rem(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a % b;
}

pub fn neg(a: anytype) @TypeOf(a) {
    return -a;
}

pub fn negWrap(a: anytype) @TypeOf(a) {
    return -%a;
}

pub fn shl(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a << b;
}

pub fn shlSaturate(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a <<| b;
}

pub fn shr(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a >> b;
}

pub fn bAnd(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a & b;
}

pub fn bOr(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a | b;
}

pub fn bXor(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a ^ b;
}

pub fn bNot(a: anytype) @TypeOf(a) {
    return ~a;
}

pub fn optUnwrapDefault(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a orelse b;
}

pub fn optUnwrap(a: anytype) @TypeOf(a) {
    return a.?;
}

pub fn errUnwrapDefault(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a catch b;
}

pub fn lAnd(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a and b;
}

pub fn lOr(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a or b;
}

pub fn not(a: anytype) @TypeOf(a) {
    return !a;
}

pub fn eq(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a == b;
}

pub fn ne(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a != b;
}

pub fn gt(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a > b;
}

pub fn ge(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a >= b;
}

pub fn lt(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a < b;
}

pub fn le(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a <= b;
}

pub fn concat(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a ++ b;
}

pub fn multiple(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a ** b;
}

pub fn deref(a: anytype) @TypeOf(a) {
    return a.*;
}
