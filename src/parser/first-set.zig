pub fn init() @This() {
    first_sets = .{Set.init()} ** grammer.len;

    while (true) {
        var updated = false;
        for (grammer) |rule| {
            prev_len = set.len;
            update(first_sets, rule, index);
            updated = updated or prev_len != set.len;
        }

        if (!updated) break;
    }

    return first_sets;
}

fn update() void {
    set = first_sets.get(index);
    if (rule.symbols.len == 0) {
        set.append(empty);
        return;
    }
    for (rule.symbols, 0..) |symbol, i| {
        switch (symbol) {
            .term => {
                set.append(symbol);
                break;
            },
            .non_term => {
                set.setUnion(getFirstSets(first_sets, symbol));
                if (!set.has(empty)) break;
                set.remove(empty);
            },
        }
    }
}
