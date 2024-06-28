const zig_test = @import("../zig_test.zig");
const assert = zig_test.assert;
const consume = zig_test.consume;

test {}

test "@addrSpaceCast" {
    const var_01: u8 = 5;
    const var_02: *const u8 = &var_01;
    const var_03: *const u8 = @addrSpaceCast(var_02);

    consume(.{ var_01, var_02, var_03 });
}

test "@addWithOverflow" {
    const var_01: u8 = 16;
    const var_02: u8 = 250;
    const var_03 = @addWithOverflow(var_01, var_02);

    try assert.expectEqual(var_03, .{ 10, 1 });
}

test "@alignCast" {
    const var_01: *align(4) const u8 = @ptrFromInt(0x04);
    const var_02: *align(2) const u8 = @alignCast(var_01);

    consume(.{ var_01, var_02 });
}

test "@alignOf" {
    const var_01: comptime_int = @alignOf(u8);

    consume(.{var_01});
}

test "@as" {
    const var_01: comptime_int = @alignOf(u8);

    consume(.{var_01});
}
test "@atomicLoad" {}
test "@atomicRmw" {}
test "@atomicStore" {}
test "@bitCast" {}
test "@bitOffsetOf" {}
test "@bitSizeOf" {}
test "@breakpoint" {}
test "@mulAdd" {}
test "@byteSwap" {}
test "@bitReverse" {}
test "@offsetOf" {}
test "@call" {}
test "@cDefine" {}
test "@cImport" {}
test "@cInclude" {}
test "@clz" {}
test "@cmpxchgStrong" {}
test "@cmpxchgWeak" {}
test "@compileError" {}
test "@compileLog" {}
test "@constCast" {}
test "@ctz" {}
test "@cUndef" {}
test "@cVaArg" {}
test "@cVaCopy" {}
test "@cVaEnd" {}
test "@cVaStart" {}
test "@divExact" {}
test "@divFloor" {}
test "@divTrunc" {}
test "@embedFile" {}
test "@enumFromInt" {}
test "@errorFromInt" {}
test "@errorName" {}
test "@errorReturnTrace" {}
test "@errorCast" {}
test "@export" {}
test "@extern" {}
test "@fence" {}
test "@field" {}
test "@fieldParentPtr" {}
test "@floatCast" {}
test "@floatFromInt" {}
test "@frameAddress" {}
test "@hasDecl" {}
test "@hasField" {}
test "@import" {}
test "@inComptime" {}
test "@intCast" {}
test "@intFromBool" {}
test "@intFromEnum" {}
test "@intFromError" {}
test "@intFromFloat" {}
test "@intFromPtr" {}
test "@max" {}
test "@memcpy" {}
test "@memset" {}
test "@min" {}
test "@wasmMemorySize" {}
test "@wasmMemoryGrow" {}
test "@mod" {}
test "@mulWithOverflow" {}
test "@panic" {}
test "@popCount" {}
test "@prefetch" {}
test "@ptrCast" {}
test "@ptrFromInt" {}
test "@rem" {}
test "@returnAddress" {}
test "@select" {}
test "@setAlignStack" {}
test "@setCold" {}
test "@setEvalBranchQuota" {}
test "@setFloatMode" {}
test "@setRuntimeSafety" {}
test "@shlExact" {}
test "@shlWithOverflow" {}
test "@shrExact" {}
test "@shuffle" {}
test "@sizeOf" {}
test "@splat" {}
test "@reduce" {}
test "@src" {}
test "@sqrt" {}
test "@sin" {}
test "@cos" {}
test "@tan" {}
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
test "@subWithOverflow" {}
test "@tagName" {}
test "@This" {}
test "@trap" {}
test "@truncate" {}
test "@Type" {}
test "@typeInfo" {}
test "@typeName" {}
test "@TypeOf" {}
test "@unionInit" {}
test "@Vector" {}
test "@volatileCast" {}
test "@workGroupId" {}
test "@workGroupSize" {}
test "@workItemId" {}
