//! Zig言語の基本の書き方を確認する。

const literals = @import("./literals.zig");
const types = @import("./types.zig");
const operators = @import("./operators.zig");
const statements = @import("./statements.zig");
const type_coercion = @import("./type_coercion.zig");
const builtin_functions = @import("./builtin_functions.zig");
const undefined_behaviors = @import("./undefined_behaviors.zig");

test {
    _ = .{
        literals,
        types,
        operators,
        statements,
        type_coercion,
        // builtin_functions,
        undefined_behaviors,
    };
}
