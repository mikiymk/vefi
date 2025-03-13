pub fn Value(T: type) type {
    return @typeInfo(T).ErrorUnion.payload;
}

pub fn Error(T: type) type {
    return @typeInfo(T).ErrorUnion.error_set;
}
