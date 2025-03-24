
pub fn size(head: anytype) usize {
    const head_ = head orelse return 0;
    var node = head_.next;
    var count: usize = 0;

    while (true) : (node = node.next) {
        count += 1;
        if (node.next == head) break;
    }

    return count;
}

pub fn clear(head: anytype, a: Allocator) void {
    const head = head orelse return;
    var node = head;

    while (true) {
        const next = node.next;
        node.deinit(a);
        node = next;
        if (node == head) break; // do-whileになる
   }
}
