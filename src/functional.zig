pub fn Callable(Args: type, Return: type) type {
    return struct {
        context: *const anyopaque,
        call_fn: *const fn (context: *const anyopaque, args: Args) Return;

        pub fn init(T: type, context: *const T, call_fn: *const fn (context: *const T, args: Args) Return) @This() {
            return .{
                .context = @ptrCast(context),
                .call_fn = struct {
                    pub fn f(context: *const anyopaque, args: Args) Return {
                        return call_fn(@ptrCast(context), args);
                    }
                }.f,
            };
        }

        pub fn call(self: @This(), args: Args) Return {
            return self.call_fn(self.context, args);
        }
    };
}
