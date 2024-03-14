//!

pub fn List(comptime T: type) type {
  return struct {
    const Self = @This();
    pub const Element = struct {
      next: ?*Element,
      value: T,
    };

    value: Element,

    pub fn push(self: Self, value: T) void {
      var e = self.value;
      while (e.next) |n| {
        e = n;
      }
      n.next = value;
    }
  };
}
