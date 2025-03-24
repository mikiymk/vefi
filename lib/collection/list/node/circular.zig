

fn Option(T: type) type {
    return if (@typeInfo(T) == .optional) T else ?T;
}

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

pub fn getNode(head: anytype, index: usize) Option(@TypeOf(head)) {
   const head = head orelse return null;
    var node = head;
    var count = index;

    while (true) : (node = node.next) {
        if (count == 0) return node;
        count -= 1;
        if (node.next == head) return null;
    }
}

pub fn getNodeFromLast(tail: anytype, index: usize) Option(@TypeOf(head)) {
    const tail = tail orelse return null;
    var node = tail;
    var count = index;

    while (true) : (node = node.prev) {
        if (count == 0) return node;
        count -= 1;
        if (node.prev == tail) return null;
    }
}

fn getLastNode(head: anytype) Option(@TypeOf(head)) {
    var prev = head orelse return null;
    var node = prev.next;

   while (node != self.head) : (node = node.next) {
        prev = node;
    }

    return prev;
}

pub fn getLastNode2(head: anytype) Option(@TypeOf(head)) {
    var prev_prev: Option(@TypeOf(head)) = null;
    var prev: Option(@TypeOf(head)) = null;
    var node = head;

    while (node) |n| : (node = n.next) {
        prev_prev = prev;
        prev = n;
    }

    return prev_prev;
}

pub fn format(w: anytype, type_name: []const u8, head: anytype) !void {
    const writer = lib.io.writer(w);

    try writer.print("{s}{{", .{type_name});
    if (self.head) |head| {
        var node = head;
        var first = true;
        while (true) : (node = node.next) {
            if (first) {
                try writer.print(" ", .{});
                first = false;
            } else {
                try writer.print(", ", .{});
           }

           try writer.print("{}", .{node});

            if (node.next == head) break;
       }
    }
   try writer.print(" }}", .{});
}
