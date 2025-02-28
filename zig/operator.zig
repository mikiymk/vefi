const utils = @import("./utils.zig");
const assert = utils.assert;
const assertVec = utils.assertVec;
const consume = utils.consume;
const equalSlices = utils.equalSlices;

test {
    _ = add;
    _ = subtract;
}

const v = struct {
    const len: usize = 3;
    const vec_usize: @Vector(len, usize) = .{ 1, 1, 1 };

    const int_01: u8 = 1;
    const int_02: u8 = 3;
    const int_03: u8 = 5;
    const int_04: u8 = 255;

    const VecInt = @Vector(len, u8);
    const vec_int_01: VecInt = .{ 1, 2, 3 };
    const vec_int_02: VecInt = .{ 4, 5, 6 };
    const vec_int_03: VecInt = .{ 255, 255, 255 };

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
        // consume(.{v.int_01 + v.int_04});
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
        // consume(.{v.vec_int_01 + v.vec_int_03});
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

    test "二項 +% (整数 + 整数)" {
        try assert(v.int_01 +% v.int_02 == 4);
        try assert(@TypeOf(v.int_01 +% v.int_02) == u8);

        // オーバーフロー
        try assert(v.int_03 +% v.int_04 == 4);
    }

    test "二項 +% (整数ベクトル + 整数ベクトル)" {
        try assertVec(v.vec_int_01 +% v.vec_int_02 == v.VecInt{ 5, 7, 9 });
        try assert(@TypeOf(v.vec_int_01 +% v.vec_int_02) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 +% v.vec_int_03 == v.VecInt{ 0, 1, 2 });
    }

    test "二項 +| (整数 + 整数)" {
        try assert(v.int_01 +| v.int_02 == 4);
        try assert(@TypeOf(v.int_01 +| v.int_02) == u8);

        // オーバーフロー
        try assert(v.int_03 +| v.int_04 == 255);
    }

    test "二項 +| (整数ベクトル + 整数ベクトル)" {
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
        // consume(.{v.int_01 - v.int_02});
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
        // consume(.{v.vec_int_01 - v.vec_int_02});
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

    test "二項 -% (整数 - 整数)" {
        try assert(v.int_02 -% v.int_01 == 2);
        try assert(@TypeOf(v.int_02 -% v.int_01) == u8);

        // オーバーフロー
        try assert(v.int_01 -% v.int_02 == 254);
    }

    test "二項 -% (整数ベクトル - 整数ベクトル)" {
        try assertVec(v.vec_int_02 -% v.vec_int_01 == v.VecInt{ 3, 3, 3 });
        try assert(@TypeOf(v.vec_int_02 -% v.vec_int_01) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 -% v.vec_int_02 == v.VecInt{ 253, 253, 253 });
    }

    test "二項 -| (整数 - 整数)" {
        try assert(v.int_02 -| v.int_01 == 2);
        try assert(@TypeOf(v.int_02 -| v.int_01) == u8);

        // オーバーフロー
        try assert(v.int_01 -| v.int_02 == 0);
    }

    test "二項 -| (整数ベクトル - 整数ベクトル)" {
        try assertVec(v.vec_int_02 -| v.vec_int_01 == v.VecInt{ 3, 3, 3 });
        try assert(@TypeOf(v.vec_int_02 -| v.vec_int_01) == v.VecInt);

        // オーバーフロー
        try assertVec(v.vec_int_01 -| v.vec_int_02 == v.VecInt{ 0, 0, 0 });
    }

    test "単項 -" {
        {
            const var_01: i8 = 13;
            const var_02: i8 = -var_01;

            try assert(var_02 == -13);
        }

        {
            const var_01: f32 = 13.75;
            const var_02: f32 = -var_01;

            try assert(var_02 == -13.75);
        }
    }

    test "単項 -%" {
        {
            const var_01: i8 = 13;
            const var_02: i8 = -%var_01;

            try assert(var_02 == -13);
        }

        {
            const var_01: i8 = -128;
            const var_02: i8 = -%var_01;

            try assert(var_02 == -128);
        }
    }
};

test "二項 *" {
    {
        const var_01: u8 = 5;
        const var_02: u8 = 6;
        const var_03: u8 = var_01 * var_02;

        try assert(var_03 == 30);
    }

    {
        const var_01: f32 = 5.5;
        const var_02: f32 = 6.75;
        const var_03: f32 = var_01 * var_02;

        try assert(var_03 == 37.125);
    }
}

test "二項 *%" {
    {
        const var_01: u8 = 5;
        const var_02: u8 = 6;
        const var_03: u8 = var_01 *% var_02;

        try assert(var_03 == 30);
    }

    {
        const var_01: u8 = 5;
        const var_02: u8 = 55;
        const var_03: u8 = var_01 *% var_02;

        try assert(var_03 == 275 % 256);
    }
}

test "二項 *|" {
    {
        const var_01: u8 = 5;
        const var_02: u8 = 6;
        const var_03: u8 = var_01 *| var_02;

        try assert(var_03 == 30);
    }

    {
        const var_01: u8 = 5;
        const var_02: u8 = 55;
        const var_03: u8 = var_01 *| var_02;

        try assert(var_03 == 255);
    }
}

test "二項 /" {
    {
        const var_01: u8 = 13;
        const var_02: u8 = 6;
        const var_03: u8 = var_01 / var_02;

        try assert(var_03 == 2);
    }

    {
        const var_01: f32 = 13.75;
        const var_02: f32 = 5.5;
        const var_03: f32 = var_01 / var_02;

        try assert(var_03 == 2.5);
    }
}

test "二項 %" {
    {
        const var_01: u8 = 13;
        const var_02: u8 = 6;
        const var_03: u8 = var_01 % var_02;

        try assert(var_03 == 1);
    }

    {
        const var_01: f32 = 13.75;
        const var_02: f32 = 5.5;
        const var_03: f32 = var_01 % var_02;

        try assert(var_03 == 2.75);
    }
}

test "二項 <<" {
    {
        const var_01: i8 = 11; // 0b0000 1011
        const var_02: u3 = 1;
        const var_03: i8 = var_01 << var_02;

        try assert(var_03 == 22);
    }

    {
        const var_01: i8 = 11; // 0b0000 1011
        const var_02: u3 = 6;
        const var_03: i8 = var_01 << var_02;

        try assert(var_03 == -64);
    }
}

test "二項 <<|" {
    {
        const var_01: i8 = 11; // 0b0000 1011
        const var_02: u3 = 1;
        const var_03: i8 = var_01 <<| var_02;

        try assert(var_03 == 22);
    }

    {
        const var_01: i8 = 11; // 0b0000 1011
        const var_02: u3 = 6;
        const var_03: i8 = var_01 <<| var_02;

        try assert(var_03 == 127);
    }
}

test "二項 >>" {
    {
        const var_01: i8 = 11; // 0b0000 1011
        const var_02: u3 = 1;
        const var_03: i8 = var_01 >> var_02;

        try assert(var_03 == 5);
    }

    {
        const var_01: i8 = 11; // 0b0000 1011
        const var_02: u3 = 6;
        const var_03: i8 = var_01 >> var_02;

        try assert(var_03 == 0);
    }
}

test "二項 &" {
    const var_01: i8 = 3; // 0b0000 0011
    const var_02: i8 = 10; // 0b0000 1010
    const var_03: i8 = var_01 & var_02;

    try assert(var_03 == 2);
}

test "二項 |" {
    const var_01: i8 = 3; // 0b0000 0011
    const var_02: i8 = 10; // 0b0000 1010
    const var_03: i8 = var_01 | var_02;

    try assert(var_03 == 11);
}

test "二項 ^" {
    const var_01: i8 = 3; // 0b0000 0011
    const var_02: i8 = 10; // 0b0000 1010
    const var_03: i8 = var_01 ^ var_02;

    try assert(var_03 == 9);
}

test "単項 ~" {
    const var_01: i8 = 83; // 0b0101 0011
    const var_02: i8 = ~var_01;

    try assert(var_02 == -84);
}
test "二項 and" {
    const var_01: bool = true and true;
    const var_02: bool = false and false;
    const var_03: bool = true and false;
    const var_04: bool = false and true;

    try assert(var_01 == true);
    try assert(var_02 == false);
    try assert(var_03 == false);
    try assert(var_04 == false);
}

test "二項 or" {
    const var_01: bool = true or true;
    const var_02: bool = false or false;
    const var_03: bool = true or false;
    const var_04: bool = false or true;

    try assert(var_01 == true);
    try assert(var_02 == false);
    try assert(var_03 == true);
    try assert(var_04 == true);
}

test "単項 !" {
    const var_01: bool = !true;
    const var_02: bool = !false;

    try assert(var_01 == false);
    try assert(var_02 == true);
}
test "二項 ==" {
    {
        const var_01: i8 = 3;
        const var_02: i8 = 4;
        const var_03: bool = var_01 == var_02;

        try assert(var_03 == false);
    }

    {
        const var_01: f32 = 3.0;
        const var_02: f32 = 3.0;
        const var_03: bool = var_01 == var_02;

        try assert(var_03 == true);
    }

    {
        const var_01: bool = true;
        const var_02: bool = true;
        const var_03: bool = var_01 == var_02;

        try assert(var_03 == true);
    }

    {
        const var_01: type = u8;
        const var_02: type = struct { u8, u8 };
        const var_03: bool = var_01 == var_02;

        try assert(var_03 == false);
    }

    {
        const var_01: ?u8 = 5;
        const var_02: ?u8 = null;
        const var_03: bool = var_01 == null;
        const var_04: bool = var_02 == null;

        try assert(var_03 == false);
        try assert(var_04 == true);
    }
}

test "二項 !=" {
    {
        const var_01: i8 = 3;
        const var_02: i8 = 4;
        const var_03: bool = var_01 != var_02;

        try assert(var_03 == true);
    }

    {
        const var_01: f32 = 3.0;
        const var_02: f32 = 3.0;
        const var_03: bool = var_01 != var_02;

        try assert(var_03 == false);
    }

    {
        const var_01: bool = true;
        const var_02: bool = true;
        const var_03: bool = var_01 != var_02;

        try assert(var_03 == false);
    }

    {
        const var_01: type = u8;
        const var_02: type = struct { u8, u8 };
        const var_03: bool = var_01 != var_02;

        try assert(var_03 == true);
    }

    {
        const var_01: ?u8 = 5;
        const var_02: ?u8 = null;
        const var_03: bool = var_01 != null;
        const var_04: bool = var_02 != null;

        try assert(var_03 == true);
        try assert(var_04 == false);
    }
}

test "二項 >" {
    {
        const var_01: i8 = 3;
        const var_02: i8 = 4;
        const var_03: bool = var_01 > var_02;

        try assert(var_03 == false);
    }

    {
        const var_01: f32 = 3.0;
        const var_02: f32 = 2.5;
        const var_03: bool = var_01 > var_02;

        try assert(var_03 == true);
    }
}

test "二項 >=" {
    {
        const var_01: i8 = 3;
        const var_02: i8 = 4;
        const var_03: bool = var_01 >= var_02;

        try assert(var_03 == false);
    }

    {
        const var_01: f32 = 3.0;
        const var_02: f32 = 2.5;
        const var_03: bool = var_01 >= var_02;

        try assert(var_03 == true);
    }
}

test "二項 <" {
    {
        const var_01: i8 = 3;
        const var_02: i8 = 4;
        const var_03: bool = var_01 < var_02;

        try assert(var_03 == true);
    }

    {
        const var_01: f32 = 3.0;
        const var_02: f32 = 2.5;
        const var_03: bool = var_01 < var_02;

        try assert(var_03 == false);
    }
}

test "二項 <=" {
    {
        const var_01: i8 = 3;
        const var_02: i8 = 4;
        const var_03: bool = var_01 <= var_02;

        try assert(var_03 == true);
    }

    {
        const var_01: f32 = 3.0;
        const var_02: f32 = 2.5;
        const var_03: bool = var_01 <= var_02;

        try assert(var_03 == false);
    }
}

test "単項 &" {
    const var_01: u8 = 5;
    const var_02: *const u8 = &var_01;

    try assert(var_02 == &var_01);
}

test "二項 ++" {
    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: [4]u8 = .{ 4, 5, 6, 7 };
        const var_03: [7]u8 = var_01 ++ var_02;

        try assert(equalSlices(var_03, .{ 1, 2, 3, 4, 5, 6, 7 }));
    }

    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: [4]u8 = .{ 4, 5, 6, 7 };
        const var_03: *const [3]u8 = &var_01;
        const var_04: *const [4]u8 = &var_02;
        const var_05: *const [7]u8 = var_03 ++ var_04;

        try assert(equalSlices(var_05, &.{ 1, 2, 3, 4, 5, 6, 7 }));
    }
}

test "二項 **" {
    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: [9]u8 = var_01 ** 3;

        try assert(equalSlices(var_02, .{ 1, 2, 3, 1, 2, 3, 1, 2, 3 }));
    }

    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: *const [3]u8 = &var_01;
        const var_03: *const [9]u8 = var_02 ** 3;

        try assert(equalSlices(var_03, &.{ 1, 2, 3, 1, 2, 3, 1, 2, 3 }));
    }
}

test "二項 orelse" {
    const var_01: ?u8 = 5;
    const var_02: ?u8 = null;
    const var_03: u8 = var_01 orelse 10;
    const var_04: u8 = var_02 orelse 11;

    try assert(var_03 == 5);
    try assert(var_04 == 11);
}

test "二項 catch" {
    const var_01: error{E}!u8 = 5;
    const var_02: error{E}!u8 = error.E;
    const var_03: u8 = var_01 catch 10;
    const var_04: u8 = var_02 catch 11;

    try assert(var_03 == 5);
    try assert(var_04 == 11);
}

test "後置 ()" {
    const function: fn () void = struct {
        pub fn f() void {}
    }.f;

    function();
}

test "後置 単項 .*" {
    const var_01: u8 = 5;
    const var_02: *const u8 = &var_01;
    const var_03: u8 = var_02.*;

    try assert(var_03 == 5);
}

test "後置 []" {
    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: u8 = var_01[0];
        const var_03: *const [2]u8 = var_01[1..];
        const var_04: *const [2]u8 = var_01[0..2];

        try assert(var_02 == 1);
        try assert(equalSlices(var_03, &.{ 2, 3 }));
        try assert(equalSlices(var_04, &.{ 1, 2 }));
    }

    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: *const [3]u8 = &var_01;
        const var_03: u8 = var_02[0];
        const var_04: *const [2]u8 = var_02[1..];
        const var_05: *const [2]u8 = var_02[0..2];

        try assert(var_03 == 1);
        try assert(equalSlices(var_04, &.{ 2, 3 }));
        try assert(equalSlices(var_05, &.{ 1, 2 }));
    }

    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: [*]const u8 = &var_01;
        const var_03: u8 = var_02[0];
        const var_04: [*]const u8 = var_02[1..];
        const var_05: [*]const u8 = var_02[0..2];

        try assert(var_03 == 1);
        try assert(var_04[0] == 2);
        try assert(var_04[1] == 3);
        try assert(var_05[0] == 1);
        try assert(var_05[1] == 2);
    }

    {
        const var_01: [3]u8 = .{ 1, 2, 3 };
        const var_02: []const u8 = &var_01;
        const var_03: u8 = var_02[0];
        const var_04: []const u8 = var_02[1..];
        const var_05: []const u8 = var_02[0..2];

        try assert(var_03 == 1);
        try assert(equalSlices(var_04, &.{ 2, 3 }));
        try assert(equalSlices(var_05, &.{ 1, 2 }));
    }
}

test "後置 単項 .?" {
    const var_01: ?u8 = 5;
    const var_02: u8 = var_01.?;

    try assert(var_02 == 5);
}
