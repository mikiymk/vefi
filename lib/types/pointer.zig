pub fn Deref(T: type) type {
    return @typeInfo(T).pointer.child;
}
