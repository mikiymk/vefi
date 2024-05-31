//!
//!

pub fn expectWriter(writer: anytype) !void {
    const size = try writer.write("abc");

    if (3 < size) {
        return error.WrongImplement;
    }
}
