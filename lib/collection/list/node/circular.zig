
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

pub fn getNode(head: anytype, index: usize) ?*Node {
   const head = head orelse return null;
    var node = head;
    var count = index;

    while (true) : (node = node.next) {
        if (count == 0) return node;
        count -= 1;
        if (node.next == head) return null;
    }
}

pub fn getNodeFromLast(tail: anytype, index: usize) ?*Node {
    const tail = tail orelse return null;
    var node = tail;
    var count = index;

    while (true) : (node = node.prev) {
        if (count == 0) return node;
        count -= 1;
        if (node.prev == tail) return null;
    }
}

fn getLastNode(head: anytype) ?*Node {
    var prev = head orelse return null;
    var node = prev.next;

   while (node != self.head) : (node = node.next) {
        prev = node;
    }

    return prev;
}

pub fn getLastNode2(head: anytype, a: Allocator) ?*Node {
    var prev_prev: ?*Node = null;
    var prev: ?*Node = null;
    var node = head;

    while (node) |n| : (node = n.next) {
        prev_prev = prev;
        prev = n;
    }

    return prev_prev;
}
