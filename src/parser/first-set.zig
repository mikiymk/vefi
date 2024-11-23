pub fn init() @This() {
    first_sets = .{Set.init()} ** grammer.len;

    while (true) {
        var updated = false;
        for (grammer) |rule| {
            updated = update(first_sets, rule, index) or updated;
        }

        if (!updated) break;
    }

    return first_sets;
}

fn update() bool {
    set = first_sets.get(index);
    for (rule.symbols, 0..) |symbol, i| {
        switch (symbol) {
            .term => {},
            .non_term => {},
            .empty => {},
        }
    }
}
