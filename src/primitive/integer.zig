pub fn isSignedInt(t: type) bool {}
pub fn isUnsignedInt(t: type) bool {}
pub fn isInt(t: type) bool {}
pub fn bitsOf(t: type) u16 {}

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    assert(isInt(@TypeOf(a)));
    return a + b;
}
