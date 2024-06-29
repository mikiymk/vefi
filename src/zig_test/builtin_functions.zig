const zig_test = @import("../zig_test.zig");
const eq = zig_test.assert.expectEqual;
const eqApprox = zig_test.assert.expectEqualApproximate;
const consume = zig_test.consume;

test {
    _ = operator_extension;
    _ = number_functions;
    _ = type_cast;
    _ = atomic;
    _ = vector;
    _ = work_group;
    _ = c;
    _ = type_info;
}

const operator_extension = struct {
    test "@addWithOverflow" {
        // 2つの値で足し算する。
        // オーバーロードした場合は1になるフラグを一緒に返す。
        try eq(@addWithOverflow(@as(u8, 16), @as(u8, 2)), .{ 18, 0 });
        try eq(@addWithOverflow(@as(u8, 16), @as(u8, 250)), .{ 10, 1 });
    }

    test "@subWithOverflow" {
        // 2つの値で引き算する。
        // オーバーロードした場合は1になるフラグを一緒に返す。
        try eq(@subWithOverflow(@as(u8, 16), @as(u8, 2)), .{ 14, 0 });
        try eq(@subWithOverflow(@as(u8, 16), @as(u8, 250)), .{ 22, 1 });
    }

    test "@mulWithOverflow" {
        // 2つの値で掛け算する。
        // オーバーロードした場合は1になるフラグを一緒に返す。
        try eq(@mulWithOverflow(@as(u8, 16), @as(u8, 2)), .{ 32, 0 });
        try eq(@mulWithOverflow(@as(u8, 16), @as(u8, 250)), .{ 160, 1 });
    }

    test "@shlWithOverflow" {
        // 2つの値で左シフトする。
        // オーバーロードした場合は1になるフラグを一緒に返す。
        try eq(@shlWithOverflow(@as(u8, 11), @as(u3, 3)), .{ 88, 0 });
        try eq(@shlWithOverflow(@as(u8, 11), @as(u3, 6)), .{ 192, 1 });
    }

    test "@divExact" {
        // 2つの値で割り算する。
        // 余りが出る計算の場合は未定義動作になる。
        try eq(@divExact(@as(u8, 15), @as(u3, 3)), 5);
        try eq(@divExact(@as(f32, 16.5), @as(f32, 5.5)), 3);
    }

    test "@divFloor" {
        // 2つの値で割り算する。
        // 割りきれない場合は負の無限大に近いほうに丸められる。
        try eq(@divFloor(@as(u8, 15), @as(u8, 3)), 5);
        try eq(@divFloor(@as(u8, 16), @as(u8, 3)), 5);
        try eq(@divFloor(@as(i8, -16), @as(i8, 3)), -6);
        try eq(@divFloor(@as(f32, -16.5), @as(f32, 5.5)), -3);
        try eq(@divFloor(@as(f32, -16.75), @as(f32, 5.5)), -4);
    }

    test "@divTrunc" {
        // 2つの値で割り算する。
        // 割りきれない場合は0に近いほうに丸められる。
        try eq(@divTrunc(@as(u8, 15), @as(u8, 3)), 5);
        try eq(@divTrunc(@as(u8, 16), @as(u8, 3)), 5);
        try eq(@divTrunc(@as(i8, -16), @as(i8, 3)), -5);
        try eq(@divTrunc(@as(f32, -16.5), @as(f32, 5.5)), -3);
        try eq(@divTrunc(@as(f32, -16.75), @as(f32, 5.5)), -3);
    }

    test "@mod" {
        // 2つの値で割り算した余りを返す。
        // つねに正の値を返す。
        try eq(@mod(@as(u8, 16), @as(u8, 3)), 1);
        try eq(@mod(@as(i8, -16), @as(i8, 3)), 2);
        try eq(@mod(@as(f32, -16.75), @as(f32, 5.5)), 5.25);
    }

    test "@rem" {
        // 2つの値で割り算した余りを返す。
        // つねに0に近い値を返す。
        try eq(@rem(@as(u8, 16), @as(u8, 3)), 1);
        try eq(@rem(@as(i8, -16), @as(i8, 3)), -1);
        try eq(@rem(@as(f32, -16.75), @as(f32, 5.5)), -0.25);
    }

    test "@shlExact" {
        // 2つの値で左シフトした余りを返す。
        // 立っているビットが外に出た場合に未定義動作になる。
        try eq(@shlExact(@as(u8, 11), @as(u3, 3)), 88);
    }
    test "@shrExact" {
        // 2つの値で右シフトした余りを返す。
        // 立っているビットが外に出た場合に未定義動作になる。
        try eq(@shrExact(@as(u8, 88), @as(u3, 3)), 11);
    }
};

const number_functions = struct {
    test "@clz" {
        // 最上位の0ビットの数をカウントする。
        try eq(@clz(@as(u8, 8)), 4);
        try eq(@clz(@as(u8, 0)), 8);
    }

    test "@ctz" {
        // 最下位の0ビットの数をカウントする。
        try eq(@ctz(@as(u8, 8)), 3);
        try eq(@ctz(@as(u8, 0)), 8);
    }

    test "@popCount" {
        // 立っているビットの数をカウントする。
        try eq(@popCount(@as(u8, 8)), 1);
        try eq(@popCount(@as(u8, 0)), 0);
    }

    test "@max" {
        // 2つの値のうち、大きい方を返す。
        const V3 = @Vector(3, u8);
        try eq(@max(@as(u8, 8), @as(u8, 9)), 9);
        try eq(@max(@as(u8, 10), @as(u8, 9)), 10);
        try eq(@max(@as(f32, 10), @as(f32, 9)), 10);
        try eq(@max(V3{ 1, 3, 5 }, V3{ 6, 4, 2 }), V3{ 6, 4, 5 });
    }

    test "@min" {
        // 2つの値のうち、小さい方を返す。
        const V3 = @Vector(3, u8);
        try eq(@min(@as(u8, 8), @as(u8, 9)), 8);
        try eq(@min(@as(u8, 10), @as(u8, 9)), 9);
        try eq(@min(@as(f32, 10), @as(f32, 9)), 9);
        try eq(@min(V3{ 1, 3, 5 }, V3{ 6, 4, 2 }), V3{ 1, 3, 2 });
    }

    test "@sqrt" {
        // 値の平方根を返す。
        const V3 = @Vector(3, f32);
        try eq(@sqrt(@as(f32, 9.0)), 3.0);
        try eq(@sqrt(@as(f32, 30.25)), 5.5);
        try eq(@sqrt(V3{ 1.0, 9.0, 25.0 }), V3{ 1.0, 3.0, 5.0 });
    }

    test "@sin" {
        // ラジアン値のサインを返す。
        const V3 = @Vector(3, f32);
        try eqApprox(@sin(@as(f32, 1.0)), 0.84147, 1e-5);
        try eqApprox(@sin(@as(f32, 3.14)), 0.00159, 1e-5);
        try eqApprox(@sin(V3{ 1.0, 2.0, 3.0 }), V3{ 0.84147, 0.90929, 0.14112 }, @splat(1e-5));
    }

    test "@cos" {
        // ラジアン値のコサインを返す。
        const V3 = @Vector(3, f32);
        try eqApprox(@cos(@as(f32, 1.0)), 0.54030, 1e-5);
        try eqApprox(@cos(@as(f32, 3.14)), -0.99999, 1e-5);
        try eqApprox(@cos(V3{ 1.0, 2.0, 3.0 }), V3{ 0.54030, -0.41614, -0.98999 }, @splat(1e-5));
    }

    test "@tan" {
        // ラジアン値のタンジェントを返す。
        const V3 = @Vector(3, f32);
        try eqApprox(@tan(@as(f32, 1.0)), 1.55740, 1e-5);
        try eqApprox(@tan(@as(f32, 3.14)), -0.00159, 1e-5);
        try eqApprox(@tan(V3{ 1.0, 2.0, 3.0 }), V3{ 1.55740, -2.18503, -0.14254 }, @splat(1e-5));
    }

    test "@exp" {}
    test "@exp2" {}
    test "@log" {}
    test "@log2" {}
    test "@log10" {}
    test "@abs" {}
    test "@floor" {}
    test "@ceil" {}
    test "@trunc" {}
    test "@round" {}
    test "@mulAdd" {}
    test "@byteSwap" {}
    test "@bitReverse" {}
    test "@memcpy" {}
    test "@memset" {}
};

const type_cast = struct {
    test "@alignCast" {
        const var_01: *align(4) const u8 = @ptrFromInt(0x04);
        const var_02: *align(2) const u8 = @alignCast(var_01);

        consume(.{ var_01, var_02 });
    }

    test "@as" {
        const var_01: comptime_int = @alignOf(u8);

        consume(.{var_01});
    }

    test "@bitCast" {}
    test "@enumFromInt" {}
    test "@errorFromInt" {}
    test "@constCast" {}
    test "@floatCast" {}
    test "@floatFromInt" {}
    test "@errorCast" {}
    test "@intCast" {}
    test "@intFromBool" {}
    test "@intFromEnum" {}
    test "@intFromError" {}
    test "@intFromFloat" {}
    test "@intFromPtr" {}
    test "@ptrCast" {}
    test "@ptrFromInt" {}
    test "@truncate" {}
    test "@volatileCast" {}
};

const atomic = struct {
    test "@atomicLoad" {}
    test "@atomicRmw" {}
    test "@atomicStore" {}
    test "@cmpxchgStrong" {}
    test "@cmpxchgWeak" {}
    test "@fence" {}
};

const vector = struct {
    test "@Vector" {}
    test "@splat" {}
    test "@reduce" {}
    test "@shuffle" {}
    test "@select" {}
};

const work_group = struct {
    test "@workGroupId" {}
    test "@workGroupSize" {}
    test "@workItemId" {}
};

const c = struct {
    test "@cDefine" {}
    test "@cImport" {}
    test "@cInclude" {}
    test "@cUndef" {}
    test "@cVaArg" {}
    test "@cVaCopy" {}
    test "@cVaEnd" {}
    test "@cVaStart" {}
};

const type_info = struct {
    test "@alignOf" {
        const var_01: comptime_int = @alignOf(u8);

        consume(.{var_01});
    }

    test "@bitOffsetOf" {}
    test "@bitSizeOf" {}
    test "@offsetOf" {}
    test "@field" {}
    test "@errorName" {}
    test "@hasDecl" {}
    test "@hasField" {}
    test "@sizeOf" {}
    test "@tagName" {}
    test "@This" {}
    test "@Type" {}
    test "@typeInfo" {}
    test "@typeName" {}
    test "@TypeOf" {}
    test "@unionInit" {}
};

test "@addrSpaceCast" {
    const var_01: u8 = 5;
    const var_02: *const u8 = &var_01;
    const var_03: *const u8 = @addrSpaceCast(var_02);

    consume(.{ var_01, var_02, var_03 });
}

test "@breakpoint" {}
test "@call" {}
test "@compileError" {}
test "@compileLog" {}
test "@embedFile" {}
test "@errorReturnTrace" {}
test "@export" {}
test "@extern" {}
test "@fieldParentPtr" {}
test "@frameAddress" {}
test "@import" {}
test "@inComptime" {}
test "@wasmMemorySize" {}
test "@wasmMemoryGrow" {}
test "@panic" {}
test "@prefetch" {}
test "@returnAddress" {}
test "@setAlignStack" {}
test "@setCold" {}
test "@setEvalBranchQuota" {}
test "@setFloatMode" {}
test "@setRuntimeSafety" {}
test "@src" {}
test "@trap" {}
