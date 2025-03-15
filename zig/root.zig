//! Zig言語の基本の書き方を確認する。

const literal = @import("./literal.zig");
const types = @import("./type.zig");
const operator = @import("./operator.zig");
const statement = @import("./statement.zig");
const type_coercion = @import("./type-coercion.zig");
const builtin_function = @import("./builtin-function.zig");

test {
    _ = .{
        @import("./literal.zig"),
        types,
        operator,
        statement,
        type_coercion,
        // builtin_function,
        @import("compile-zig.zig"),
    };
}
