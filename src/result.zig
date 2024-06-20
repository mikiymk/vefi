pub fn Result(S: type, F: type) type {
    return union(enum) {
        success: Success,
        failure: Failure,

        pub const Success = S;
        pub const Failure = F;

        pub fn isResult(Self: type) bool {
            return Self == Result(Self.Success, Self.Failure);
        }
    };
}
