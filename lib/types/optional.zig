pub fn Optional(T: type) type {
    return @Type(.{ .optional = .{ .child = T } });
}

pub fn NonOptional(T: type) type {
    return @typeInfo(T).optional.child;
}

pub fn Deref(T: type) type {
    const Child = @typeInfo(@typeInfo(T).optional.child).Pointer.child;

    return @Type(.{ .optional = .{ .child = Child } });
}

/// `?*T` -> `?T`
pub fn deref(value: anytype) Deref(@TypeOf(value)) {
    if (value) |non_optional_value| {
        return non_optional_value.*;
    } else {
        return null;
    }
}

pub inline fn map(optional: anytype, ReturnType: type, map_fn: fn (non_optional: NonOptional(@TypeOf(optional))) ReturnType) ?ReturnType {
    return if (optional) |non_optional| map_fn(non_optional) else null;
}
