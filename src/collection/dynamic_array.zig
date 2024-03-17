/// 動的配列
pub fn DynamicArray(comptime T: type) type {
    return struct {
        value: []T,
        size: usize,

        pub fn push() void {}

        pub fn pop() void {}

        pub fn get(n: usize) *T {
            _ = n;
        }

        pub fn insert(n: usize) void {
            _ = n;
        }

        pub fn delete(n: usize) void {
            _ = n;
        }

        fn extendSize() void {}
    };
}
