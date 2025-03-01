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

const v = struct {
    const len: usize = 3;
    const vec_usize: @Vector(len, usize) = .{ 1, 1, 1 };

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

    const array_01: [3]u8 = .{ 1, 2, 3 };

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
};

const add = struct {
    test "二項 + (整数 + 整数)" {
        try assert(v.int_01 + v.int_02 == 4);
        try assert(@TypeOf(v.int_01 + v.int_02) == u8);

        // オーバーフロー
        // consume(v.int_01 + v.int_04);
    }

    test "二項 + (浮動小数点数 + 浮動小数点数)" {
        try assert(v.float_01 + v.float_02 == 3.75);
        try assert(@TypeOf(v.float_01 + v.float_02) == f32);
    }

    test "二項 + (複数要素ポインター + 整数)" {
        try assert((v.multi_ptr_01 + v.int_01)[0] == 2);
        try assert(@TypeOf(v.multi_ptr_01 + v.int_01) == v.MultiPtr);
    }

    test "二項 + (Cポインター + 整数)" {
        try assert((v.c_ptr_01 + v.int_01)[0] == 2);
        try assert(@TypeOf(v.c_ptr_01 + v.int_01) == v.CPtr);
    }

    test "二項 + (整数ベクトル + 整数ベクトル)" {
        try assertVec(v.vec_int_01 + v.vec_int_02 == v.VecInt{ 5, 7, 9 });
        try assert(@TypeOf(v.vec_int_01 + v.vec_int_02) == v.VecInt);

        // オーバーフロー
        // consume(v.vec_int_01 + v.vec_int_03);
    }

    test "二項 + (浮動小数点数ベクトル + 浮動小数点数ベクトル)" {
        try assertVec(v.vec_float_01 + v.vec_float_02 == v.VecFloat{ 5.5, 8.0, 10.5 });
        try assert(@TypeOf(v.vec_float_01 + v.vec_float_02) == v.VecFloat);
    }

    test "二項 + (複数要素ポインターベクトル + 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((v.vec_multi_ptr + v.vec_usize)[0] == 2);
        // try assert(@TypeOf(v.vec_multi_ptr + v.vec_usize) == [*]const u8);
    }

    test "二項 + (Cポインターベクトル + 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((v.vec_c_ptr + v.vec_usize)[0] == 2);
        // try assert(@TypeOf(v.vec_c_ptr + v.vec_usize) == [*c]const u8);
    }

    test "二項 +% (整数 +% 整数)" {
        try assert(v.int_01 +% v.int_02 == 4);
        try assert(@TypeOf(v.int_01 +% v.int_02) == u8);

        // オーバーフロー
        try assert(v.int_03 +% v.int_04 == 4);
    }

    test "二項 +% (整数ベクトル +% 整数ベクトル)" {
        try assertVec(v.vec_int_01 +% v.vec_int_02 == v.VecInt{ 5, 7, 9 });
        try assert(@TypeOf(v.vec_int_01 +% v.vec_int_02) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 +% v.vec_int_03 == v.VecInt{ 0, 1, 2 });
    }

    test "二項 +| (整数 +| 整数)" {
        try assert(v.int_01 +| v.int_02 == 4);
        try assert(@TypeOf(v.int_01 +| v.int_02) == u8);

        // オーバーフロー
        try assert(v.int_03 +| v.int_04 == 255);
    }

    test "二項 +| (整数ベクトル +| 整数ベクトル)" {
        try assertVec(v.vec_int_01 +| v.vec_int_02 == v.VecInt{ 5, 7, 9 });
        try assert(@TypeOf(v.vec_int_01 +| v.vec_int_02) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 +| v.vec_int_03 == v.VecInt{ 255, 255, 255 });
    }
};

const subtract = struct {
    test "二項 - (整数 - 整数)" {
        try assert(v.int_02 - v.int_01 == 2);
        try assert(@TypeOf(v.int_02 - v.int_01) == u8);

        // オーバーフロー
        // consume(v.int_01 - v.int_02);
    }

    test "二項 - (浮動小数点数 - 浮動小数点数)" {
        try assert(v.float_02 - v.float_03 == -1.25);
        try assert(@TypeOf(v.float_02 - v.float_03) == f32);
    }

    test "二項 - (単要素ポインター - 単要素ポインター)" {
        // TODO: 0.13.0
        // try assert(v.single_ptr_02 - v.single_ptr_01 == 1);
        // try assert(@TypeOf(v.single_ptr_02 - v.single_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインター - 複数要素ポインター)" {
        // TODO: 0.13.0
        // try assert(v.multi_ptr_02 - v.multi_ptr_01 == 1);
        // try assert(@TypeOf(v.multi_ptr_02 - v.multi_ptr_01) == usize);
    }

    test "二項 - (Cポインター - Cポインター)" {
        // TODO: 0.13.0
        // try assert(v.c_ptr_02 - v.c_ptr_01 == 1);
        // try assert(@TypeOf(v.c_ptr_02 - v.c_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインター - 整数)" {
        try assert((v.multi_ptr_02 - v.int_01)[0] == 1);
        try assert(@TypeOf(v.multi_ptr_02 - v.int_01) == v.MultiPtr);
    }

    test "二項 - (Cポインター - 整数)" {
        try assert((v.c_ptr_02 - v.int_01)[0] == 1);
        try assert(@TypeOf(v.c_ptr_02 - v.int_01) == v.CPtr);
    }

    test "二項 - (整数ベクトル - 整数ベクトル)" {
        try assertVec(v.vec_int_02 - v.vec_int_01 == v.VecInt{ 3, 3, 3 });
        try assert(@TypeOf(v.vec_int_02 - v.vec_int_01) == v.VecInt);

        // オーバーフロー
        // consume(v.vec_int_01 - v.vec_int_02);
    }

    test "二項 - (浮動小数点数ベクトル - 浮動小数点数ベクトル)" {
        try assertVec(v.vec_float_02 - v.vec_float_01 == v.VecFloat{ 3.0, 3.0, 3.0 });
        try assert(@TypeOf(v.vec_float_02 - v.vec_float_01) == v.VecFloat);
    }

    test "二項 - (単要素ポインターベクトル - 単要素ポインターベクトル)" {
        // TODO: 0.13.0
        // try assert(v.vec_single_ptr_02 - v.vec_single_ptr_01 == 1);
        // try assert(@TypeOf(v.vec_single_ptr_02 - v.vec_single_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインターベクトル - 複数要素ポインターベクトル)" {
        // TODO: 0.13.0
        // try assert(v.vec_multi_ptr_02 - v.vec_multi_ptr_01 == 1);
        // try assert(@TypeOf(v.vec_multi_ptr_02 - v.vec_multi_ptr_01) == usize);
    }

    test "二項 - (Cポインターベクトル - Cポインターベクトル)" {
        // TODO: 0.13.0
        // try assert(v.vec_c_ptr_02 - v.vec_c_ptr_01 == 1);
        // try assert(@TypeOf(v.vec_c_ptr_02 - v.vec_c_ptr_01) == usize);
    }

    test "二項 - (複数要素ポインターベクトル - 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((v.vec_multi_ptr_02 - v.vec_int_01)[0] == 1);
        // try assert(@TypeOf(v.vec_multi_ptr_01 - v.vec_int_01) == v.MultiPtr);
    }

    test "二項 - (Cポインターベクトル - 整数ベクトル)" {
        // TODO: 0.13.0
        // try assert((v.vec_c_ptr_02 - v.vec_int_01)[0] == 1);
        // try assert(@TypeOf(v.vec_c_ptr_02 - v.vec_int_01) == v.CPtr);
    }

    test "二項 -% (整数 -% 整数)" {
        try assert(v.int_02 -% v.int_01 == 2);
        try assert(@TypeOf(v.int_02 -% v.int_01) == u8);

        // オーバーフロー
        try assert(v.int_01 -% v.int_02 == 254);
    }

    test "二項 -% (整数ベクトル -% 整数ベクトル)" {
        try assertVec(v.vec_int_02 -% v.vec_int_01 == v.VecInt{ 3, 3, 3 });
        try assert(@TypeOf(v.vec_int_02 -% v.vec_int_01) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 -% v.vec_int_02 == v.VecInt{ 253, 253, 253 });
    }

    test "二項 -| (整数 -| 整数)" {
        try assert(v.int_02 -| v.int_01 == 2);
        try assert(@TypeOf(v.int_02 -| v.int_01) == u8);

        // オーバーフロー
        try assert(v.int_01 -| v.int_02 == 0);
    }

    test "二項 -| (整数ベクトル -| 整数ベクトル)" {
        try assertVec(v.vec_int_02 -| v.vec_int_01 == v.VecInt{ 3, 3, 3 });
        try assert(@TypeOf(v.vec_int_02 -| v.vec_int_01) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 -| v.vec_int_02 == v.VecInt{ 0, 0, 0 });
    }

    test "単項 - (-整数)" {
        try assert(-v.int_05 == -1);
        try assert(@TypeOf(-v.int_05) == i8);

        // オーバーフロー
        // consume(-v.int_07);
    }

    test "単項 - (-浮動小数点数)" {
        try assert(-v.float_01 == -1.25);
        try assert(@TypeOf(-v.float_01) == f32);
    }

    test "単項 - (-整数ベクトル)" {
        try assertVec(-v.vec_int_04 == v.VecInt2{ -1, -2, -3 });
        try assert(@TypeOf(-v.vec_int_04) == v.VecInt2);

        // オーバーフロー
        // consume(-v.vec_int_06);
    }

    test "単項 - (-浮動小数点数ベクトル)" {
        try assertVec(-v.vec_float_01 == v.VecFloat{ -1.25, -2.5, -3.75 });
        try assert(@TypeOf(-v.vec_float_01) == v.VecFloat);
    }

    test "単項 -% (-%整数)" {
        try assert(-%v.int_05 == -1);
        try assert(@TypeOf(-%v.int_05) == i8);

        // オーバーフロー
        try assert(-%v.int_07 == -128);
    }

    test "単項 -% (-%整数ベクトル)" {
        try assertVec(-%v.vec_int_04 == v.VecInt2{ -1, -2, -3 });
        try assert(@TypeOf(-%v.vec_int_04) == v.VecInt2);

        // オーバーフロー
        try assertVec(-%v.vec_int_06 == v.VecInt2{ -128, -128, -128 });
    }
};

const multiply = struct {
    test "二項 * (整数 * 整数)" {
        try assert(v.int_01 * v.int_02 == 3);
        try assert(@TypeOf(v.int_01 * v.int_02) == u8);

        // オーバーフロー
        // consume(v.int_03 * v.int_04);
    }

    test "二項 * (浮動小数点数 * 浮動小数点数)" {
        try assert(v.float_01 * v.float_02 == 3.125);
        try assert(@TypeOf(v.float_01 * v.float_02) == f32);
    }

    test "二項 * (整数ベクトル * 整数ベクトル)" {}

    test "二項 * (浮動小数点数ベクトル * 浮動小数点数ベクトル)" {}

    test "二項 *% (整数 *% 整数)" {}

    test "二項 *% (整数ベクトル *% 整数ベクトル)" {}

    test "二項 *| (整数 *| 整数)" {}

    test "二項 *| (整数ベクトル *| 整数ベクトル)" {}
};

const divide = struct {
    test "二項 / (整数 / 整数)" {}

    test "二項 / (浮動小数点数 / 浮動小数点数)" {}

    test "二項 / (整数ベクトル / 整数ベクトル)" {}

    test "二項 / (浮動小数点数ベクトル / 浮動小数点数ベクトル)" {}

    test "二項 % (整数 % 整数)" {}

    test "二項 % (浮動小数点数 % 浮動小数点数)" {}

    test "二項 % (整数ベクトル % 整数ベクトル)" {}

    test "二項 % (浮動小数点数ベクトル % 浮動小数点数ベクトル)" {}
};

const shift = struct {
    test "二項 << (整数 << 整数)" {}

    test "二項 << (整数ベクトル << 整数ベクトル)" {}

    test "二項 <<| (整数 <<| 整数)" {}

    test "二項 <<| (整数ベクトル <<| 整数ベクトル)" {}

    test "二項 >> (整数 >> 整数)" {}

    test "二項 >> (整数ベクトル >> 整数ベクトル)" {}
};

const bitwise = struct {
    test "二項 & (整数 & 整数)" {}

    test "二項 & (整数ベクトル & 整数ベクトル)" {}

    test "二項 | (整数 | 整数)" {}

    test "二項 | (整数ベクトル | 整数ベクトル)" {}

    test "二項 ^ (整数 ^ 整数)" {}

    test "二項 ^ (整数ベクトル ^ 整数ベクトル)" {}

    test "単項 ~ (~整数)" {}

    test "単項 ~ (~整数ベクトル)" {}
};

const logical = struct {
    test "二項 and (論理値 and 論理値)" {}

    test "二項 and (論理値ベクトル and 論理値ベクトル)" {}

    test "二項 or (論理値 or 論理値)" {}

    test "二項 or (論理値ベクトル or 論理値ベクトル)" {}

    test "単項 ! (!論理値)" {}

    test "単項 ! (!論理値ベクトル)" {}
};

const compare_eq = struct {
    test "二項 == (論理値 == 論理値)" {}

    test "二項 == (論理値ベクトル == 論理値ベクトル)" {}

    test "二項 == (整数 == 整数)" {}

    test "二項 == (整数ベクトル == 整数ベクトル)" {}

    test "二項 == (浮動小数点数 == 浮動小数点数)" {}

    test "二項 == (浮動小数点数ベクトル == 浮動小数点数ベクトル)" {}

    test "二項 == (単要素ポインター == 単要素ポインター)" {}

    test "二項 == (単要素ポインターベクトル == 単要素ポインターベクトル)" {}

    test "二項 == (複数要素ポインター == 複数要素ポインター)" {}

    test "二項 == (複数要素ポインターベクトル == 複数要素ポインターベクトル)" {}

    test "二項 == (Cポインター == Cポインター)" {}

    test "二項 == (Cポインターベクトル == Cポインターベクトル)" {}

    test "二項 == (列挙型 == 列挙型)" {}

    test "二項 == (タグ付き共用体型 == 列挙型)" {}

    test "二項 == (型 == 型)" {}
};

const compare_ord = struct {
    test "二項 > (整数 > 整数)" {}

    test "二項 > (整数ベクトル > 整数ベクトル)" {}

    test "二項 > (浮動小数点数 > 浮動小数点数)" {}

    test "二項 > (浮動小数点数ベクトル > 浮動小数点数ベクトル)" {}

    test "二項 >= (整数 >= 整数)" {}

    test "二項 >= (整数ベクトル >= 整数ベクトル)" {}

    test "二項 >= (浮動小数点数 >= 浮動小数点数)" {}

    test "二項 >= (浮動小数点数ベクトル >= 浮動小数点数ベクトル)" {}

    test "二項 < (整数 < 整数)" {}

    test "二項 < (整数ベクトル < 整数ベクトル)" {}

    test "二項 < (浮動小数点数 < 浮動小数点数)" {}

    test "二項 < (浮動小数点数ベクトル < 浮動小数点数ベクトル)" {}

    test "二項 <= (整数 <= 整数)" {}

    test "二項 <= (整数ベクトル <= 整数ベクトル)" {}

    test "二項 <= (浮動小数点数 <= 浮動小数点数)" {}

    test "二項 <= (浮動小数点数ベクトル <= 浮動小数点数ベクトル)" {}
};

const array = struct {
    test "二項 ++ (配列 ++ 配列)" {}

    test "二項 ++ (ベクトル ++ ベクトル)" {}

    test "二項 ++ (タプル ++ タプル)" {}

    test "二項 ** (配列 ** 整数)" {}

    test "二項 ** (ベクトル ** 整数)" {}

    test "二項 ** (タプル ** 整数)" {}
};

test "単項 &" {}

test "二項 orelse (オプション orelse 非オプション)" {}

test "二項 orelse (オプション orelse noreturn)" {}

test "二項 catch (エラー catch 非エラー)" {}

test "二項 catch (エラー catch noreturn)" {}
