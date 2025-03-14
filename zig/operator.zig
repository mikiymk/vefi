const utils = @import("./utils.zig");
const assert = utils.assert;
const consume = utils.consume;
const equalSlices = utils.equalSlices;

pub fn assertVec(value: @Vector(3, bool)) !void {
    return assert(@reduce(.And, value));
}

test {
    _ = add;
    _ = subtract;
    _ = multiply;
    _ = divide;
    _ = shift;
    _ = bitwise;
    _ = logical;
    _ = compare_eq;
    _ = compare_ord;
    _ = array;
}

const len: usize = 3;
const vec_usize: @Vector(len, usize) = .{ 1, 1, 1 };

const bool_01: bool = true;
const bool_02: bool = false;

const VecBool = @Vector(len, bool);
const vec_bool_01: VecBool = .{ true, true, true };
const vec_bool_02: VecBool = .{ false, false, false };
const vec_bool_03: VecBool = .{ true, false, true };

const int_01: u8 = 1;
const int_02: u8 = 3;
const int_03: u8 = 5;
const int_04: u8 = 255;
const int_05: i8 = 1;
const int_06: i8 = -3;
const int_07: i8 = -128;

const VecInt = @Vector(len, u8);
const VecInt2 = @Vector(len, i8);
const vec_int_01: VecInt = .{ 1, 2, 3 };
const vec_int_02: VecInt = .{ 4, 5, 6 };
const vec_int_03: VecInt = .{ 255, 255, 255 };
const vec_int_04: VecInt2 = .{ 1, 2, 3 };
const vec_int_05: VecInt2 = .{ 127, 127, 127 };
const vec_int_06: VecInt2 = .{ -128, -128, -128 };

const float_01: f32 = 1.25;
const float_02: f32 = 2.5;
const float_03: f32 = 3.75;

const VecFloat = @Vector(len, f32);
const vec_float_01: VecFloat = .{ 1.25, 2.5, 3.75 };
const vec_float_02: VecFloat = .{ 4.25, 5.5, 6.75 };

const Array = [3]u8;
const array_01: Array = .{ 1, 2, 3 };
const array_02: Array = .{ 4, 5, 6 };

const Tuple = struct { u8, f32, u8 };
const tuple_01: Tuple = .{ 1, 1.5, 2 };
const tuple_02: Tuple = .{ 3, 4.5, 6 };

const SinglePtr = *const u8;
const single_ptr_01: SinglePtr = @ptrCast(&array_01);
const single_ptr_02: SinglePtr = @ptrCast(@as(MultiPtr, &array_01) + 1);

const VecSinglePtr = @Vector(len, *const u8);
const vec_single_ptr_01: VecSinglePtr = .{ single_ptr_01, single_ptr_01, single_ptr_01 };
const vec_single_ptr_02: VecSinglePtr = .{ single_ptr_02, single_ptr_02, single_ptr_02 };

const MultiPtr = [*]const u8;
const multi_ptr_01: MultiPtr = &array_01;
const multi_ptr_02: MultiPtr = @as(MultiPtr, &array_01) + 1;

const VecMultiPtr = @Vector(len, [*]const u8);
const vec_multi_ptr_01: VecMultiPtr = .{ multi_ptr_01, multi_ptr_01, multi_ptr_01 };
const vec_multi_ptr_02: VecMultiPtr = .{ multi_ptr_02, multi_ptr_02, multi_ptr_02 };

const CPtr = [*c]const u8;
const c_ptr_01: CPtr = &array_01;
const c_ptr_02: CPtr = @as(CPtr, &array_01) + 1;

const VecCPtr = @Vector(len, [*c]const u8);
const vec_c_ptr_01: VecCPtr = .{ c_ptr_01, c_ptr_01, c_ptr_01 };
const vec_c_ptr_02: VecCPtr = .{ c_ptr_02, c_ptr_02, c_ptr_02 };

const Enum = enum { v1, v2, v3 };

const Option = ?u8;
const option_01: Option = null;
const option_02: Option = 1;

const Error = error{Error}!u8;
const error_01: Error = error.Error;
const error_02: Error = 1;

const add = struct {
    test "二項 + (整数 + 整数)" {
        try assert(int_01 + int_02 == 4);
        try assert(@TypeOf(int_01 + int_02) == u8);

        // オーバーフロー
        // consume(int_01 + int_04);
    }

    test "二項 + (浮動小数点数 + 浮動小数点数)" {
        try assert(float_01 + float_02 == 3.75);
        try assert(@TypeOf(float_01 + float_02) == f32);
    }

    test "二項 + (複数要素ポインター + 整数)" {
        try assert((multi_ptr_01 + int_01)[0] == 2);
        try assert(@TypeOf(multi_ptr_01 + int_01) == MultiPtr);
    }

    test "二項 + (Cポインター + 整数)" {
        try assert((c_ptr_01 + int_01)[0] == 2);
        try assert(@TypeOf(c_ptr_01 + int_01) == CPtr);
    }

    test "二項 + (整数ベクトル + 整数ベクトル)" {
        try assertVec(vec_int_01 + vec_int_02 == VecInt{ 5, 7, 9 });
        try assert(@TypeOf(vec_int_01 + vec_int_02) == VecInt);

        // オーバーフロー
        // consume(vec_int_01 + vec_int_03);
    }

    test "二項 + (浮動小数点数ベクトル + 浮動小数点数ベクトル)" {
        try assertVec(vec_float_01 + vec_float_02 == VecFloat{ 5.5, 8.0, 10.5 });
        try assert(@TypeOf(vec_float_01 + vec_float_02) == VecFloat);
    }

    test "二項 + (複数要素ポインターベクトル + 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((vec_multi_ptr_01 + vec_usize)[0] == 2);
        // try assert(@TypeOf(vec_multi_ptr_01 + vec_usize) == [*]const u8);
    }

    test "二項 + (Cポインターベクトル + 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((vec_c_ptr + vec_usize)[0] == 2);
        // try assert(@TypeOf(vec_c_ptr + vec_usize) == [*c]const u8);
    }

    test "二項 +% (整数 +% 整数)" {
        try assert(int_01 +% int_02 == 4);
        try assert(@TypeOf(int_01 +% int_02) == u8);

        // オーバーフロー
        try assert(int_03 +% int_04 == 4);
    }

    test "二項 +% (整数ベクトル +% 整数ベクトル)" {
        try assertVec(vec_int_01 +% vec_int_02 == VecInt{ 5, 7, 9 });
        try assert(@TypeOf(vec_int_01 +% vec_int_02) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_01 +% vec_int_03 == VecInt{ 0, 1, 2 });
    }

    test "二項 +| (整数 +| 整数)" {
        try assert(int_01 +| int_02 == 4);
        try assert(@TypeOf(int_01 +| int_02) == u8);

        // オーバーフロー
        try assert(int_03 +| int_04 == 255);
    }

    test "二項 +| (整数ベクトル +| 整数ベクトル)" {
        try assertVec(vec_int_01 +| vec_int_02 == VecInt{ 5, 7, 9 });
        try assert(@TypeOf(vec_int_01 +| vec_int_02) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_01 +| vec_int_03 == VecInt{ 255, 255, 255 });
    }
};

const subtract = struct {
    test "二項 - (整数 - 整数)" {
        try assert(int_02 - int_01 == 2);
        try assert(@TypeOf(int_02 - int_01) == u8);

        // オーバーフロー
        // consume(int_01 - int_02);
    }

    test "二項 - (浮動小数点数 - 浮動小数点数)" {
        try assert(float_02 - float_03 == -1.25);
        try assert(@TypeOf(float_02 - float_03) == f32);
    }

    test "二項 - (単要素ポインター - 単要素ポインター)" {
        // TODO: 0.13.0
        // try assert(single_ptr_02 - single_ptr_01 == 1);
        // try assert(@TypeOf(single_ptr_02 - single_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインター - 複数要素ポインター)" {
        // TODO: 0.13.0
        // try assert(multi_ptr_02 - multi_ptr_01 == 1);
        // try assert(@TypeOf(multi_ptr_02 - multi_ptr_01) == usize);
    }

    test "二項 - (Cポインター - Cポインター)" {
        // TODO: 0.13.0
        // try assert(c_ptr_02 - c_ptr_01 == 1);
        // try assert(@TypeOf(c_ptr_02 - c_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインター - 整数)" {
        try assert((multi_ptr_02 - int_01)[0] == 1);
        try assert(@TypeOf(multi_ptr_02 - int_01) == MultiPtr);
    }

    test "二項 - (Cポインター - 整数)" {
        try assert((c_ptr_02 - int_01)[0] == 1);
        try assert(@TypeOf(c_ptr_02 - int_01) == CPtr);
    }

    test "二項 - (整数ベクトル - 整数ベクトル)" {
        try assertVec(vec_int_02 - vec_int_01 == VecInt{ 3, 3, 3 });
        try assert(@TypeOf(vec_int_02 - vec_int_01) == VecInt);

        // オーバーフロー
        // consume(vec_int_01 - vec_int_02);
    }

    test "二項 - (浮動小数点数ベクトル - 浮動小数点数ベクトル)" {
        try assertVec(vec_float_02 - vec_float_01 == VecFloat{ 3.0, 3.0, 3.0 });
        try assert(@TypeOf(vec_float_02 - vec_float_01) == VecFloat);
    }

    test "二項 - (単要素ポインターベクトル - 単要素ポインターベクトル)" {
        // TODO: 0.13.0
        // try assert(vec_single_ptr_02 - vec_single_ptr_01 == 1);
        // try assert(@TypeOf(vec_single_ptr_02 - vec_single_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインターベクトル - 複数要素ポインターベクトル)" {
        // TODO: 0.13.0
        // try assert(vec_multi_ptr_02 - vec_multi_ptr_01 == 1);
        // try assert(@TypeOf(vec_multi_ptr_02 - vec_multi_ptr_01) == usize);
    }

    test "二項 - (Cポインターベクトル - Cポインターベクトル)" {
        // TODO: 0.13.0
        // try assert(vec_c_ptr_02 - vec_c_ptr_01 == 1);
        // try assert(@TypeOf(vec_c_ptr_02 - vec_c_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインターベクトル - 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((vec_multi_ptr_02 - vec_int_01)[0] == 1);
        // try assert(@TypeOf(vec_multi_ptr_01 - vec_int_01) == MultiPtr);
    }

    test "二項 - (Cポインターベクトル - 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((vec_c_ptr_02 - vec_int_01)[0] == 1);
        // try assert(@TypeOf(vec_c_ptr_02 - vec_int_01) == CPtr);
    }

    test "二項 -% (整数 -% 整数)" {
        try assert(int_02 -% int_01 == 2);
        try assert(@TypeOf(int_02 -% int_01) == u8);

        // オーバーフロー
        try assert(int_01 -% int_02 == 254);
    }

    test "二項 -% (整数ベクトル -% 整数ベクトル)" {
        try assertVec(vec_int_02 -% vec_int_01 == VecInt{ 3, 3, 3 });
        try assert(@TypeOf(vec_int_02 -% vec_int_01) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_01 -% vec_int_02 == VecInt{ 253, 253, 253 });
    }

    test "二項 -| (整数 -| 整数)" {
        try assert(int_02 -| int_01 == 2);
        try assert(@TypeOf(int_02 -| int_01) == u8);

        // オーバーフロー
        try assert(int_01 -| int_02 == 0);
    }

    test "二項 -| (整数ベクトル -| 整数ベクトル)" {
        try assertVec(vec_int_02 -| vec_int_01 == VecInt{ 3, 3, 3 });
        try assert(@TypeOf(vec_int_02 -| vec_int_01) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_01 -| vec_int_02 == VecInt{ 0, 0, 0 });
    }

    test "単項 - (-整数)" {
        try assert(-int_05 == -1);
        try assert(@TypeOf(-int_05) == i8);

        // オーバーフロー
        // consume(-int_07);
    }

    test "単項 - (-浮動小数点数)" {
        try assert(-float_01 == -1.25);
        try assert(@TypeOf(-float_01) == f32);
    }

    test "単項 - (-整数ベクトル)" {
        try assertVec(-vec_int_04 == VecInt2{ -1, -2, -3 });
        try assert(@TypeOf(-vec_int_04) == VecInt2);

        // オーバーフロー
        // consume(-vec_int_06);
    }

    test "単項 - (-浮動小数点数ベクトル)" {
        try assertVec(-vec_float_01 == VecFloat{ -1.25, -2.5, -3.75 });
        try assert(@TypeOf(-vec_float_01) == VecFloat);
    }

    test "単項 -% (-%整数)" {
        try assert(-%int_05 == -1);
        try assert(@TypeOf(-%int_05) == i8);

        // オーバーフロー
        try assert(-%int_07 == -128);
    }

    test "単項 -% (-%整数ベクトル)" {
        try assertVec(-%vec_int_04 == VecInt2{ -1, -2, -3 });
        try assert(@TypeOf(-%vec_int_04) == VecInt2);

        // オーバーフロー
        try assertVec(-%vec_int_06 == VecInt2{ -128, -128, -128 });
    }
};

const multiply = struct {
    test "二項 * (整数 * 整数)" {
        try assert(int_01 * int_02 == 3);
        try assert(@TypeOf(int_01 * int_02) == u8);

        // オーバーフロー
        // consume(int_03 * int_04);
    }

    test "二項 * (浮動小数点数 * 浮動小数点数)" {
        try assert(float_01 * float_02 == 3.125);
        try assert(@TypeOf(float_01 * float_02) == f32);
    }

    test "二項 * (整数ベクトル * 整数ベクトル)" {
        try assertVec(vec_int_01 * vec_int_02 == VecInt{ 4, 10, 18 });
        try assert(@TypeOf(vec_int_01 * vec_int_02) == VecInt);

        // オーバーフロー
        // consume(vec_int_01 * vec_int_03);
    }

    test "二項 * (浮動小数点数ベクトル * 浮動小数点数ベクトル)" {
        try assertVec(vec_float_01 * vec_float_02 == VecFloat{ 5.3125, 13.75, 25.3125 });
        try assert(@TypeOf(vec_float_01 * vec_float_02) == VecFloat);
    }

    test "二項 *% (整数 *% 整数)" {
        try assert(int_01 *% int_02 == 3);
        try assert(@TypeOf(int_01 *% int_02) == u8);

        // オーバーフロー
        try assert(int_03 *% int_04 == 251);
    }

    test "二項 *% (整数ベクトル *% 整数ベクトル)" {
        try assertVec(vec_int_01 *% vec_int_02 == VecInt{ 4, 10, 18 });
        try assert(@TypeOf(vec_int_01 *% vec_int_02) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_01 *% vec_int_03 == VecInt{ 255, 254, 253 });
    }

    test "二項 *| (整数 *| 整数)" {
        try assert(int_01 *| int_02 == 3);
        try assert(@TypeOf(int_01 *| int_02) == u8);

        // オーバーフロー
        try assert(int_03 *| int_04 == 255);
    }

    test "二項 *| (整数ベクトル *| 整数ベクトル)" {
        try assertVec(vec_int_01 *| vec_int_02 == VecInt{ 4, 10, 18 });
        try assert(@TypeOf(vec_int_01 *| vec_int_02) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_01 *| vec_int_03 == VecInt{ 255, 255, 255 });
    }
};

const divide = struct {
    test "二項 / (整数 / 整数)" {
        try assert(int_02 / int_01 == 3);
        try assert(@TypeOf(int_02 / int_01) == u8);

        // ゼロ除算
        // consume(int_01 / 0);

        // オーバーフロー
        // consume(int_07 / -1);
    }

    test "二項 / (浮動小数点数 / 浮動小数点数)" {
        try assert(float_02 / float_01 == 2.0);
        try assert(@TypeOf(float_02 / float_01) == f32);
    }

    test "二項 / (整数ベクトル / 整数ベクトル)" {
        try assertVec(vec_int_02 / vec_int_01 == VecInt{ 4, 2, 2 });
        try assert(@TypeOf(vec_int_02 / vec_int_01) == VecInt);

        // ゼロ除算
        // consume(vec_int_01 / VecInt{ 0, 0, 0 });

        // オーバーフロー
        // consume(vec_int_06 / VecInt2{ -1, -1, -1 });
    }

    test "二項 / (浮動小数点数ベクトル / 浮動小数点数ベクトル)" {
        try assertVec(vec_float_02 / vec_float_01 == VecFloat{ 3.4, 2.2, 1.8 });
        try assert(@TypeOf(vec_float_02 / vec_float_01) == VecFloat);
    }

    test "二項 % (整数 % 整数)" {
        try assert(int_02 % int_01 == 0);
        try assert(@TypeOf(int_02 % int_01) == u8);

        // ゼロ除算
        // consume(int_01 % 0);
    }

    test "二項 % (浮動小数点数 % 浮動小数点数)" {
        try assert(float_02 % float_01 == 0.0);
        try assert(@TypeOf(float_02 % float_01) == f32);
    }

    test "二項 % (整数ベクトル % 整数ベクトル)" {
        try assertVec(vec_int_02 % vec_int_01 == VecInt{ 0, 1, 0 });
        try assert(@TypeOf(vec_int_02 % vec_int_01) == VecInt);

        // ゼロ除算
        // consume(vec_int_01 % VecInt{ 0, 0, 0 });
    }

    test "二項 % (浮動小数点数ベクトル % 浮動小数点数ベクトル)" {
        try assertVec(vec_float_02 % vec_float_01 == VecFloat{ 0.5, 0.5, 3.0 });
        try assert(@TypeOf(vec_float_02 % vec_float_01) == VecFloat);
    }
};

const shift = struct {
    test "二項 << (整数 << 整数)" {
        try assert(int_01 << int_02 == 8);
        try assert(@TypeOf(int_01 << int_02) == u8);

        // オーバーフロー
        try assert(int_04 << 7 == 128);
    }

    test "二項 << (整数ベクトル << 整数ベクトル)" {
        try assertVec(vec_int_01 << vec_int_02 == VecInt{ 16, 64, 192 });
        try assert(@TypeOf(vec_int_01 << vec_int_02) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_03 << VecInt{ 1, 2, 3 } == VecInt{ 254, 252, 248 });
    }

    test "二項 <<| (整数 <<| 整数)" {
        try assert(int_01 <<| int_02 == 8);
        try assert(@TypeOf(int_01 <<| int_02) == u8);

        // オーバーフロー
        try assert(int_04 <<| 7 == 255);
    }

    test "二項 <<| (整数ベクトル <<| 整数ベクトル)" {
        try assertVec(vec_int_01 <<| vec_int_02 == VecInt{ 16, 64, 192 });
        try assert(@TypeOf(vec_int_01 <<| vec_int_02) == VecInt);

        // オーバーフロー
        try assertVec(vec_int_03 <<| VecInt{ 1, 2, 3 } == VecInt{ 255, 255, 255 });
    }

    test "二項 >> (整数 >> 整数)" {
        try assert(int_02 >> int_01 == 1);
        try assert(@TypeOf(int_02 >> int_01) == u8);
    }

    test "二項 >> (整数ベクトル >> 整数ベクトル)" {
        try assertVec(vec_int_03 >> vec_int_01 == VecInt{ 127, 63, 31 });
        try assert(@TypeOf(vec_int_03 >> vec_int_01) == VecInt);
    }
};

const bitwise = struct {
    test "二項 & (整数 & 整数)" {
        try assert(int_01 & int_02 == 1);
        try assert(@TypeOf(int_01 & int_02) == u8);
    }

    test "二項 & (整数ベクトル & 整数ベクトル)" {
        try assertVec(vec_int_01 & vec_int_02 == VecInt{ 0, 0, 2 });
        try assert(@TypeOf(vec_int_01 & vec_int_02) == VecInt);
    }

    test "二項 | (整数 | 整数)" {
        try assert(int_01 | int_02 == 3);
        try assert(@TypeOf(int_01 | int_02) == u8);
    }

    test "二項 | (整数ベクトル | 整数ベクトル)" {
        try assertVec(vec_int_01 | vec_int_02 == VecInt{ 5, 7, 7 });
        try assert(@TypeOf(vec_int_01 | vec_int_02) == VecInt);
    }

    test "二項 ^ (整数 ^ 整数)" {
        try assert(int_01 ^ int_02 == 2);
        try assert(@TypeOf(int_01 ^ int_02) == u8);
    }

    test "二項 ^ (整数ベクトル ^ 整数ベクトル)" {
        try assertVec(vec_int_01 ^ vec_int_02 == VecInt{ 5, 7, 5 });
        try assert(@TypeOf(vec_int_01 ^ vec_int_02) == VecInt);
    }

    test "単項 ~ (~整数)" {
        try assert(~int_01 == 254);
        try assert(@TypeOf(~int_01) == u8);
    }

    test "単項 ~ (~整数ベクトル)" {
        try assertVec(~vec_int_01 == VecInt{ 254, 253, 252 });
        try assert(@TypeOf(~vec_int_01) == VecInt);
    }
};

const logical = struct {
    test "二項 and (論理値 and 論理値)" {
        try assert((bool_01 and bool_02) == false);
        try assert(@TypeOf(bool_01 and bool_02) == bool);
    }

    test "二項 and (論理値ベクトル and 論理値ベクトル)" {
        // TODO
        // try assertVec((vec_bool_01 and vec_bool_02) == VecBool{ false, false, false });
        // try assert(@TypeOf(vec_bool_01 and vec_bool_02) == VecBool);
    }

    test "二項 or (論理値 or 論理値)" {
        try assert((bool_01 or bool_02) == true);
        try assert(@TypeOf((bool_01 or bool_02)) == bool);
    }

    test "二項 or (論理値ベクトル or 論理値ベクトル)" {
        // TODO
        // try assertVec((vec_bool_01 or vec_bool_02) == VecBool{ false, false, false });
        // try assert(@TypeOf(vec_bool_01 or vec_bool_02) == VecBool);
    }

    test "単項 ! (!論理値)" {
        try assert(!bool_01 == false);
        try assert(@TypeOf(!bool_01) == bool);
    }

    test "単項 ! (!論理値ベクトル)" {
        // TODO
        // try assertVec(!vec_bool_01 == VecBool{ false, false, false });
        // try assert(@TypeOf(!vec_bool_01) == VecBool);
    }
};

const compare_eq = struct {
    test "二項 == (論理値 == 論理値)" {
        try assert((bool_01 == bool_02) == false);
        try assert(@TypeOf(bool_01 == bool_02) == bool);
    }

    test "二項 == (論理値ベクトル == 論理値ベクトル)" {
        try assertVec((vec_bool_02 == vec_bool_03) == VecBool{ false, true, false });
        try assert(@TypeOf(vec_bool_02 == vec_bool_03) == VecBool);
    }

    test "二項 == (整数 == 整数)" {
        try assert((int_01 == int_02) == false);
        try assert(@TypeOf(int_01 == int_02) == bool);
    }

    test "二項 == (整数ベクトル == 整数ベクトル)" {
        try assertVec((vec_int_01 == vec_int_02) == VecBool{ false, false, false });
        try assert(@TypeOf(vec_int_01 == vec_int_02) == VecBool);
    }

    test "二項 == (浮動小数点数 == 浮動小数点数)" {
        try assert((float_01 == float_02) == false);
        try assert(@TypeOf(float_01 == float_02) == bool);
    }

    test "二項 == (浮動小数点数ベクトル == 浮動小数点数ベクトル)" {
        try assertVec((vec_float_01 == vec_float_02) == VecBool{ false, false, false });
        try assert(@TypeOf(vec_float_01 == vec_float_02) == VecBool);
    }

    test "二項 == (単要素ポインター == 単要素ポインター)" {
        try assert((single_ptr_01 == single_ptr_02) == false);
        try assert(@TypeOf(single_ptr_01 == single_ptr_02) == bool);
    }

    test "二項 == (単要素ポインターベクトル == 単要素ポインターベクトル)" {
        try assertVec((vec_single_ptr_01 == vec_single_ptr_02) == VecBool{ false, false, false });
        try assert(@TypeOf(vec_single_ptr_01 == vec_single_ptr_02) == VecBool);
    }

    test "二項 == (複数要素ポインター == 複数要素ポインター)" {
        try assert((multi_ptr_01 == multi_ptr_02) == false);
        try assert(@TypeOf(multi_ptr_01 == multi_ptr_02) == bool);
    }

    test "二項 == (複数要素ポインターベクトル == 複数要素ポインターベクトル)" {
        try assertVec((vec_multi_ptr_01 == vec_multi_ptr_02) == VecBool{ false, false, false });
        try assert(@TypeOf(vec_multi_ptr_01 == vec_multi_ptr_02) == VecBool);
    }

    test "二項 == (Cポインター == Cポインター)" {
        try assert((c_ptr_01 == c_ptr_02) == false);
        try assert(@TypeOf(c_ptr_01 == c_ptr_02) == bool);
    }

    test "二項 == (Cポインターベクトル == Cポインターベクトル)" {
        try assertVec((vec_c_ptr_01 == vec_c_ptr_02) == VecBool{ false, false, false });
        try assert(@TypeOf(vec_c_ptr_01 == vec_c_ptr_02) == VecBool);
    }

    test "二項 == (列挙型 == 列挙型)" {
        try assert((Enum.v1 == Enum.v2) == false);
        try assert(@TypeOf(Enum.v1 == Enum.v2) == bool);
    }

    test "二項 == (型 == 型)" {
        try assert((u8 == f32) == false);
        try assert(@TypeOf(u8 == f32) == bool);
    }
};

const compare_ord = struct {
    test "二項 > (整数 > 整数)" {
        try assert((int_02 > int_01) == true);
        try assert(@TypeOf(int_02 > int_01) == bool);
    }

    test "二項 > (整数ベクトル > 整数ベクトル)" {
        try assertVec((vec_int_02 > vec_int_01) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_int_02 > vec_int_01) == VecBool);
    }

    test "二項 > (浮動小数点数 > 浮動小数点数)" {
        try assert((float_02 > float_01) == true);
        try assert(@TypeOf(float_02 > float_01) == bool);
    }

    test "二項 > (浮動小数点数ベクトル > 浮動小数点数ベクトル)" {
        try assertVec((vec_float_02 > vec_float_01) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_float_02 > vec_float_01) == VecBool);
    }

    test "二項 >= (整数 >= 整数)" {
        try assert((int_02 >= int_01) == true);
        try assert(@TypeOf(int_02 >= int_01) == bool);
    }

    test "二項 >= (整数ベクトル >= 整数ベクトル)" {
        try assertVec((vec_int_02 >= vec_int_01) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_int_02 >= vec_int_01) == VecBool);
    }

    test "二項 >= (浮動小数点数 >= 浮動小数点数)" {
        try assert((float_02 >= float_01) == true);
        try assert(@TypeOf(float_02 >= float_01) == bool);
    }

    test "二項 >= (浮動小数点数ベクトル >= 浮動小数点数ベクトル)" {
        try assertVec((vec_float_02 >= vec_float_01) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_float_02 >= vec_float_01) == VecBool);
    }

    test "二項 < (整数 < 整数)" {
        try assert((int_01 < int_02) == true);
        try assert(@TypeOf(int_01 < int_02) == bool);
    }

    test "二項 < (整数ベクトル < 整数ベクトル)" {
        try assertVec((vec_int_01 < vec_int_02) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_int_01 < vec_int_02) == VecBool);
    }

    test "二項 < (浮動小数点数 < 浮動小数点数)" {
        try assert((float_01 < float_02) == true);
        try assert(@TypeOf(float_01 < float_02) == bool);
    }

    test "二項 < (浮動小数点数ベクトル < 浮動小数点数ベクトル)" {
        try assertVec((vec_float_01 < vec_float_02) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_float_01 < vec_float_02) == VecBool);
    }

    test "二項 <= (整数 <= 整数)" {
        try assert((int_01 <= int_02) == true);
        try assert(@TypeOf(int_01 <= int_02) == bool);
    }

    test "二項 <= (整数ベクトル <= 整数ベクトル)" {
        try assertVec((vec_int_01 <= vec_int_02) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_int_01 <= vec_int_02) == VecBool);
    }

    test "二項 <= (浮動小数点数 <= 浮動小数点数)" {
        try assert((float_01 <= float_02) == true);
        try assert(@TypeOf(float_01 <= float_02) == bool);
    }

    test "二項 <= (浮動小数点数ベクトル <= 浮動小数点数ベクトル)" {
        try assertVec((vec_float_01 <= vec_float_02) == VecBool{ true, true, true });
        try assert(@TypeOf(vec_float_01 <= vec_float_02) == VecBool);
    }
};

const array = struct {
    test "二項 ++ (配列 ++ 配列)" {
        try assert((array_01 ++ array_02).len == 6);
        try assert((array_01 ++ array_02)[0] == 1);
        try assert(@TypeOf(array_01 ++ array_02) == [6]u8);
    }

    test "二項 ++ (タプル ++ タプル)" {
        try assert((tuple_01 ++ tuple_02).len == 6);
        try assert((tuple_01 ++ tuple_02)[0] == 1);
        try assert(@TypeOf((tuple_01 ++ tuple_02)[0]) == u8);
        // try assert(@TypeOf(tuple_01 ++ tuple_02) == struct { u8, f32, u8, u8, f32, u8 });
    }

    test "二項 ** (配列 ** 整数)" {
        try assert((array_01 ** 3).len == 9);
        try assert((array_01 ** 3)[0] == 1);
        try assert(@TypeOf(array_01 ** 3) == [9]u8);
    }

    test "二項 ** (タプル ** 整数)" {
        try assert((tuple_01 ** 3).len == 9);
        try assert((tuple_01 ** 3)[0] == 1);
        try assert(@TypeOf((tuple_01 ** 3)[0]) == u8);
        // try assert(@TypeOf(tuple_01 ** 3) == struct { u8, f32, u8, u8, f32, u8, u8, f32, u8 });
    }
};

test "単項 &" {
    try assert(@TypeOf(&int_01) == *const u8);
}

test "二項 orelse (オプション orelse 非オプション)" {
    try assert(option_01 orelse int_01 == 1);
    try assert(@TypeOf(option_01 orelse int_01) == u8);
}

test "二項 orelse (オプション orelse noreturn)" {
    try assert(option_01 orelse return == 1);
    try assert(@TypeOf(option_01 orelse return) == u8);
}

test "二項 catch (エラー catch 非エラー)" {
    try assert(error_01 catch int_01 == 1);
    try assert(@TypeOf(error_01 catch int_01) == u8);
}

test "二項 catch (エラー catch noreturn)" {
    try assert(error_02 catch return == 1);
    try assert(@TypeOf(error_02 catch return) == u8);
}
