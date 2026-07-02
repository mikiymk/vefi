const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

// メモ: [a, b) は a を含み b を含まない値の範囲

pub const LoggedSortTarget = @import("sort/LoggedSortTarget.zig");
pub const LoggedAllocator = @import("sort/LoggedAllocator.zig");

pub const slow_sort = @import("sort/slow_sort.zig");
pub const bubble_sort = @import("sort/bubble_sort.zig");
pub const insertion_sort = @import("sort/insertion_sort.zig");
pub const tree_sort = @import("sort/tree_sort.zig");
pub const quick_sort = @import("sort/quick_sort.zig");
pub const merge_sort = @import("sort/merge_sort.zig");

/// 図書館ソート。
/// 隙間を空けて挿入ソートする。
pub fn librarySort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    // 難しそう
    _ = allocator;
    _ = target;
}

/// シェアソート。
/// 配列を2次元行列として行ごと、列ごとにソートする。
pub fn shearSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    _ = target;
}

// fn mergeInsertionSortInternal(allocator: Allocator, target: *LoggedSortTarget, start: usize, end: usize) !void {
//     // 範囲を2つに分け、ペアを大きい方と小さい方に分ける。
//     var i = start + 1;
//     while (i < end) : (i += 2) {
//         if (target.lessThan(i, i - 1)) {
//             target.swap(i - 1, i);
//         }
//     }
// }

// pub fn mergeInsertionSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
//     // 1. Group the elements of X into ⌊ n / 2 ⌋ pairs of elements, arbitrarily, leaving one element unpaired if there is an odd number of elements.
//     // 2. Perform ⌊ n / 2 ⌋ comparisons, one per pair, to determine the larger of the two elements in each pair.
//     // 3. Recursively sort the ⌊ n / 2 ⌋ larger elements from each pair, creating a sorted sequence S of ⌊ n / 2 ⌋ of the input elements, in ascending order, using the merge-insertion sort.
//     // 4. Insert at the start of S the element that was paired with the first and smallest element of S.
//     // 5. Insert the remaining ⌈ n / 2 ⌉ − 1 elements of X ∖ S into S, one at a time, with a specially chosen insertion ordering described below. Use binary search in subsequences of S (as described below) to determine the position at which each element should be inserted.
//     try mergeInsertionSortInternal(allocator, target, 0, target.length());
// }

// patience sort
// cube sort
// Flux sort
// Crum sort
// Library sort
// Strand sort
// Cycle sort
// Non-recursive quicksort

// Bead sort
// Merge-insertion sort
// Spaghetti (Poll) sort
// Sorting network
// Bitonic sorter
// Unshuffle Sort

// 非比較ソート

// bucket sort
// Pigeonhole sort
// Bucket sort
// Counting sort
// LSD Radix Sort
// MSD Radix Sort
// Spreadsort
// Burstsort
// Flashsort

const SortFn = *const fn (Allocator, *LoggedSortTarget) Allocator.Error!void;
/// 高速・安定ソート
const sorts_fast_stable = [_]SortFn{
    merge_sort.mergeSort1,
    merge_sort.mergeSort2,
    merge_sort.mergeSortInPlace1,
    merge_sort.mergeSortInPlace2,
    merge_sort.mergeSortInPlace3,
    merge_sort.timSort,
        // power sort
        // block merge sort
};

/// 高速・不安定ソート
const sorts_fast_unstable = [_]SortFn{
    quick_sort.quickSort1,
    quick_sort.quickSort2,
    quick_sort.quickSort3,
    quick_sort.introSort,
    tree_sort.heapSort1,
    tree_sort.heapSort2,
    tree_sort.heapSort3,
    tree_sort.smoothSort1,
    tree_sort.smoothSort2,
        // tournament sort
};

/// 中速・安定ソート
const sorts_mid_stable = [_]SortFn{
    bubble_sort.bubbleSort1,
    bubble_sort.bubbleSort2,
    bubble_sort.bubbleSort3,
    bubble_sort.shakerSort1,
    bubble_sort.shakerSort2,
    bubble_sort.oddEvenSort,
    insertion_sort.gnomeSort,
    insertion_sort.insertionSort1,
    insertion_sort.insertionSort2,
    insertion_sort.binaryInsertionSort,
    tree_sort.treeSort,
        // library sort
};

/// 中速・不安定ソート
const sorts_mid_unstable = [_]SortFn{
    bubble_sort.combSort,
    insertion_sort.selectionSort,
    insertion_sort.shellSort1,
    insertion_sort.shellSort2,
    insertion_sort.shellSort3,
        // shear sort
};

const sorts_slow_unstable = [_]SortFn{
    slow_sort.stoogeSort,
    slow_sort.slowSort,
};

const sorts_very_slow_unstable = [_]SortFn{
    slow_sort.bogoSort,
    slow_sort.bozoSort,
};

fn testSortAlgorithm(allocator: Allocator, func: SortFn, array_length: usize, expect_stable: bool) !void {
    var target = LoggedSortTarget{};
    defer target.deinit(allocator);
    try target.resize(allocator, array_length);
    target.reset(.double_shuffle);

    try func(allocator, &target);

    if (!target.isSorted()) {
        return error.NotSorted;
    }

    if (expect_stable and !target.isStableSorted()) {
        return error.NotStableSorted;
    }
}

test "sort" {
    const allocator = std.testing.allocator;

    for (sorts_fast_stable) |sort_fn| {
        try testSortAlgorithm(allocator, sort_fn, 0, true);
        try testSortAlgorithm(allocator, sort_fn, 1000, true);
    }

    for (sorts_fast_unstable) |sort_fn| {
        try testSortAlgorithm(allocator, sort_fn, 0, false);
        try testSortAlgorithm(allocator, sort_fn, 1000, false);
    }

    for (sorts_mid_stable) |sort_fn| {
        try testSortAlgorithm(allocator, sort_fn, 0, true);
        try testSortAlgorithm(allocator, sort_fn, 100, true);
    }

    for (sorts_mid_unstable) |sort_fn| {
        try testSortAlgorithm(allocator, sort_fn, 0, false);
        try testSortAlgorithm(allocator, sort_fn, 100, false);
    }

    for (sorts_slow_unstable) |sort_fn| {
        try testSortAlgorithm(allocator, sort_fn, 0, false);
        try testSortAlgorithm(allocator, sort_fn, 15, false);
    }

    for (sorts_very_slow_unstable) |sort_fn| {
        try testSortAlgorithm(allocator, sort_fn, 0, false);
        try testSortAlgorithm(allocator, sort_fn, 8, false);
    }
}
