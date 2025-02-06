const utils = @import("./utils.zig");
const assert = utils.assert;
const consume = utils.consume;
const equalSlices = utils.equalSlices;

test {
    _ = arithmetic;
    _ = bitwise;
    _ = logical;
    _ = compare;
}

const arithmetic = struct {
    test "中置 二項 +" {
        {
            const var_01: u8 = 5;
            const var_02: u8 = 6;
            const var_03: u8 = var_01 + var_02;

            try assert(var_03 == 11);
        }

        {
            const var_01: f32 = 5.5;
            const var_02: f32 = 6.75;
            const var_03: f32 = var_01 + var_02;

            try assert(var_03 == 12.25);
        }

        {
            const var_01: [3]u8 = .{ 1, 2, 3 };
            const var_02: [*]const u8 = &var_01;
            const var_03: usize = 1;
            const var_04: [*]const u8 = var_02 + var_03;

            try assert(var_04[0] == 2);
        }
    }

    test "中置 二項 +%" {
        {
            const var_01: u8 = 5;
            const var_02: u8 = 6;
            const var_03: u8 = var_01 +% var_02;

            try assert(var_03 == 11);
        }

        {
            const var_01: u8 = 5;
            const var_02: u8 = 255;
            const var_03: u8 = var_01 +% var_02;

            try assert(var_03 == 4);
        }
    }

    test "中置 二項 +|" {
        {
            const var_01: u8 = 5;
            const var_02: u8 = 6;
            const var_03: u8 = var_01 +| var_02;

            try assert(var_03 == 11);
        }

        {
            const var_01: u8 = 5;
            const var_02: u8 = 255;
            const var_03: u8 = var_01 +| var_02;

            try assert(var_03 == 255);
        }
    }

    test "中置 二項 -" {
        {
            const var_01: u8 = 5;
            const var_02: u8 = 3;
            const var_03: u8 = var_01 - var_02;

            try assert(var_03 == 2);
        }

        {
            const var_01: f32 = 5.5;
            const var_02: f32 = 6.75;
            const var_03: f32 = var_01 - var_02;

            try assert(var_03 == -1.25);
        }
    }

    test "中置 二項 -%" {
        {
            const var_01: u8 = 5;
            const var_02: u8 = 3;
            const var_03: u8 = var_01 -% var_02;

            try assert(var_03 == 2);
        }

        {
            const var_01: u8 = 5;
            const var_02: u8 = 8;
            const var_03: u8 = var_01 -% var_02;

            try assert(var_03 == 253);
        }
    }

    test "中置 二項 -|" {
        {
            const var_01: u8 = 5;
            const var_02: u8 = 3;
            const var_03: u8 = var_01 -| var_02;

            try assert(var_03 == 2);
        }

        {
            const var_01: u8 = 5;
            const var_02: u8 = 8;
            const var_03: u8 = var_01 -| var_02;

            try assert(var_03 == 0);
        }
    }

    test "中置 二項 *" {
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

    test "中置 二項 *%" {
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

    test "中置 二項 *|" {
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

    test "中置 二項 /" {
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

    test "中置 二項 %" {
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

    test "前置 単項 -" {
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

    test "前置 単項 -%" {
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

const bitwise = struct {
    test "中置 二項 <<" {
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

    test "中置 二項 <<|" {
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

    test "中置 二項 >>" {
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

    test "中置 二項 &" {
        const var_01: i8 = 3; // 0b0000 0011
        const var_02: i8 = 10; // 0b0000 1010
        const var_03: i8 = var_01 & var_02;

        try assert(var_03 == 2);
    }

    test "中置 二項 |" {
        const var_01: i8 = 3; // 0b0000 0011
        const var_02: i8 = 10; // 0b0000 1010
        const var_03: i8 = var_01 | var_02;

        try assert(var_03 == 11);
    }

    test "中置 二項 ^" {
        const var_01: i8 = 3; // 0b0000 0011
        const var_02: i8 = 10; // 0b0000 1010
        const var_03: i8 = var_01 ^ var_02;

        try assert(var_03 == 9);
    }

    test "前置 単項 ~" {
        const var_01: i8 = 83; // 0b0101 0011
        const var_02: i8 = ~var_01;

        try assert(var_02 == -84);
    }
};

const logical = struct {
    test "中置 二項 and" {
        const var_01: bool = true and true;
        const var_02: bool = false and false;
        const var_03: bool = true and false;
        const var_04: bool = false and true;

        try assert(var_01 == true);
        try assert(var_02 == false);
        try assert(var_03 == false);
        try assert(var_04 == false);
    }

    test "中置 二項 or" {
        const var_01: bool = true or true;
        const var_02: bool = false or false;
        const var_03: bool = true or false;
        const var_04: bool = false or true;

        try assert(var_01 == true);
        try assert(var_02 == false);
        try assert(var_03 == true);
        try assert(var_04 == true);
    }

    test "前置 単項 !" {
        const var_01: bool = !true;
        const var_02: bool = !false;

        try assert(var_01 == false);
        try assert(var_02 == true);
    }
};

const compare = struct {
    test "中置 二項 ==" {
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

    test "中置 二項 !=" {
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

    test "中置 二項 >" {
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

    test "中置 二項 >=" {
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

    test "中置 二項 <" {
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

    test "中置 二項 <=" {
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
};

test "後置 ()" {
    const function: fn () void = struct {
        pub fn f() void {}
    }.f;

    function();
}

test "前置 単項 &" {
    const var_01: u8 = 5;
    const var_02: *const u8 = &var_01;

    try assert(var_02 == &var_01);
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

test "中置 二項 ++" {
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

test "中置 二項 **" {
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

test "中置 二項 orelse" {
    const var_01: ?u8 = 5;
    const var_02: ?u8 = null;
    const var_03: u8 = var_01 orelse 10;
    const var_04: u8 = var_02 orelse 11;

    try assert(var_03 == 5);
    try assert(var_04 == 11);
}

test "後置 単項 .?" {
    const var_01: ?u8 = 5;
    const var_02: u8 = var_01.?;

    try assert(var_02 == 5);
}

test "中置 二項 catch" {
    const var_01: error{E}!u8 = 5;
    const var_02: error{E}!u8 = error.E;
    const var_03: u8 = var_01 catch 10;
    const var_04: u8 = var_02 catch 11;

    try assert(var_03 == 5);
    try assert(var_04 == 11);
}
