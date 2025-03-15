pub fn Value(T: type) type {
    return @typeInfo(T).error_union.payload;
}

pub fn Error(T: type) type {
    return @typeInfo(T).error_union.error_set;
}
