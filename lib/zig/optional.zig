pub fn Deref(comptime v: type) type {
    const t = @typeInfo(@typeInfo(v).Optional.child).Pointer.child;

    return @Type(.{ .Optional = .{ .child = t } });
}

/// `?*T` -> `?T`
pub fn deref(v: anytype) Deref(@TypeOf(v)) {
    if (v) |vv| {
        return vv.*;
    } else {
        return null;
    }
}
