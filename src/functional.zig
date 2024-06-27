const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn Callable(Args: type, Return: type) type {
    return struct {
        context: *const anyopaque,
        call_fn: *const fn (context: *const anyopaque, args: Args) Return,

        pub fn init(T: type, context: *const T, call_fn: *const fn (context: *const T, args: Args) Return) @This() {
            return .{
                .context = @ptrCast(context),
                .call_fn = struct {
                    pub fn f(inner_context: *const anyopaque, args: Args) Return {
                        return call_fn(@ptrCast(inner_context), args);
                    }
                }.f,
            };
        }

        pub fn call(self: @This(), args: Args) Return {
            return self.call_fn(self.context, args);
        }
    };
}
