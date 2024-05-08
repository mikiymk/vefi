pub fn Map(K: type, V: type) type {
    return struct {
        pub const Key = K;
        pub const Value = V;
    };
}
