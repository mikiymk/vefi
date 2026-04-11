const std = @import("std");

const Int = u64;
const List = std.array_list.Aligned(Int, null);
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn prime(a: Allocator) !void {
    const start_time = std.time.microTimestamp();
    var primes = List.empty; // これまでの素数
    // 1桁の素数
    try addPrime(a, &primes, 2);
    try addPrime(a, &primes, 3);
    try addPrime(a, &primes, 5);
    try addPrime(a, &primes, 7);

    var n: Int = 11;
    while (true) {
        for ([_]Int{ 2, 4, 2, 2 }) |diff| { //1の位が1、3、7、9のみ判定
            const n_sqrt: Int = @intFromFloat(@sqrt(@as(f80, @floatFromInt(n)))); // nの平方根
            for (primes.items) |i| {
                if (n_sqrt < i) {
                    try addPrime(a, &primes, n);
                    break;
                }
                if (n % i == 0) break;
            }
            n += diff;
        }

        if (1_000_000 < n) break;
    }
    const end_time = std.time.microTimestamp();
    print("\n{d}\ntime: {d} ms", .{ primes.items.len, end_time - start_time });
}

fn addPrime(a: Allocator, primes: *List, p: Int) !void {
    try primes.append(a, p);
    // print("{d} ", .{p});
}
