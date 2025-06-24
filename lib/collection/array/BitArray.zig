//! ビット配列

pub const Item = u1;
const usize_length = @bitSizeOf(usize);

array: []usize,
length: usize,

pub fn init() @This() {}

pub fn size() {
    return self.array.len * usize_length + self.length;
}

pub fn get(index: usize) {
    const large_index = index / usize_length;
    const small_indec = index % usize_length;

    return self.array[large_index] >> small_index & 1;
}
