const std = @import("std");
const lib = @import("root.zig");

/// java: https://docs.oracle.com/javase/jp/8/docs/technotes/guides/intl/encoding.doc.html
/// javascript: https://encoding.spec.whatwg.org/#names-and-labels
/// javascript: https://developer.mozilla.org/docs/Web/API/Encoding_API/Encodings
/// python: https://docs.python.org/3/library/codecs.html#standard-encodings
/// .net: https://learn.microsoft.com/dotnet/fundamentals/runtime-libraries/system-text-encoding
/// icu: https://icu4c-demos.unicode.org/icu-bin/convexp
pub const Encoding = enum {
    us_ascii,
    utf8,
    utf16,
    utf16le,
    utf16be,
    utf32,
};

pub const ascii_string = struct {};
pub const utf8_string = struct {};

test {
    std.testing.refAllDecls(@This());
}
