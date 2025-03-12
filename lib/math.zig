const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const integer = @import("math/integer.zig");
pub const big_integer = struct {};
pub const ratio = struct {};
pub const fixed_point = struct {};
pub const float_point = @import("math/float_point.zig");
pub const big_float_point = struct {};
pub const complex = struct {};

pub const Order = enum {
    /// left == right
    equal,
    /// left > right
    greater_than,
    /// left < right
    less_than,
};

pub fn compare(left: anytype, right: @TypeOf(left)) Order {
    if (left > right) return .greater_than;
    if (left < right) return .less_than;
    return .equal;
}

pub fn absDiff(left: anytype, right: @TypeOf(left)) lib.types.Integer.Unsigned(@TypeOf(left)) {
    if (left > right) {
        return left - right;
    } else {
        return right - left;
    }
}

// https://cpprefjp.github.io/reference/cmath.html
// https://docs.oracle.com/javase/jp/23/docs/api/java.base/java/lang/Math.html
// https://docs.python.org/ja/3.13/library/math.html

pub const e: comptime_float = 0.0;
pub const pi: comptime_float = 0.0;
pub const tau: comptime_float = 0.0;

pub fn sin() void {}
pub fn cos() void {}
pub fn tan() void {}
pub fn asin() void {}
pub fn acos() void {}
pub fn atan() void {}
pub fn atan2() void {}

pub fn sinh() void {}
pub fn cosh() void {}
pub fn tanh() void {}
pub fn asinh() void {}
pub fn acosh() void {}
pub fn atanh() void {}

pub fn exp() void {}
pub fn exp2() void {}
pub fn expm1() void {}

pub fn log() void {}
pub fn log2() void {}
pub fn log10() void {}
pub fn log1p() void {}

pub fn ldexp() void {}
pub fn frexp() void {}
pub fn logb() void {}
pub fn ilogb() void {}
pub fn modf() void {}
pub fn scalb() void {}

pub fn pow() void {}
pub fn sqrt() void {}
pub fn cbrt() void {}
pub fn hypot() void {}

pub fn abs() void {}

pub fn erf() void {}
pub fn erfc() void {}
pub fn tgamma() void {}
pub fn lgamma() void {}

pub fn assoc_laguerre() void {}
pub fn assoc_legendre() void {}
pub fn beta() void {}
pub fn comp_ellint_1() void {}
pub fn comp_ellint_2() void {}
pub fn comp_ellint_3() void {}
pub fn cyl_bessel_i() void {}
pub fn cyl_bessel_j() void {}
pub fn cyl_bessel_k() void {}
pub fn cyl_neumann() void {}
pub fn ellint_1() void {}
pub fn ellint_2() void {}
pub fn ellint_3() void {}
pub fn expint() void {}
pub fn hermite() void {}
pub fn laguerre() void {}
pub fn legendre() void {}
pub fn riemann_zeta() void {}
pub fn sph_bessel() void {}
pub fn sph_legendre() void {}
pub fn sph_neumann() void {}

pub fn ceil() void {}
pub fn floor() void {}
pub fn round() void {}
pub fn trunc() void {}
pub fn rint() void {}

pub fn mod() void {}
pub fn rem() void {}

pub fn max() void {}
pub fn min() void {}
pub fn dim() void {}

pub fn fma() void {}

pub fn lerp() void {}

pub fn fpclassify() void {}
pub fn isfinite() void {}
pub fn isinf() void {}
pub fn isnan() void {}
pub fn isnormal() void {}
pub fn signbit() void {}

pub fn isgreater() void {}
pub fn isgreaterequal() void {}
pub fn isless() void {}
pub fn islessequal() void {}
pub fn islessgreater() void {}
pub fn isunordered() void {}

pub fn clamp() void {}
pub fn copySign() void {}
pub fn nextAfter() void {}
pub fn nextUp() void {}
pub fn nextDown() void {}
pub fn signum() void {}
pub fn ulp() void {}

pub fn comb() void {}
pub fn factorial() void {}
pub fn gcd() void {}
pub fn lcm() void {}
pub fn perm() void {}
