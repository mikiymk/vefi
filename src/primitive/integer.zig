pub fn isSignedInt(T: type) bool {
    return switch (@typeinfo(T)) {
        .Int => |i| i.signed,
        else => false,
    };
}

pub fn isUnsignedInt(T: type) bool {
    return switch (@typeinfo(T)) {
        .Int => |i| !i.signed,
        else => false,
    };
}

pub fn isInt(T: type) bool {
    return @typeinfo(T) == .Int;
}

pub fn bitsOf(T: type) u16 {
    assert(T);

    return @typeinfo(T).Int.bits;
}

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    assert(isInt(@TypeOf(a)));
    return a + b;
}
