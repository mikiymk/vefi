grammer: Grammer,
director_sets: DirectorSet,

pub fn init(grammer: Grammer) @This() {
    const first_sets = FirstSet.init(grammar);
    const follow_sets = FollowSet.init(grammar, first_sets);
    const director_sets = DirectorSet.init(first_sets, follow_sets);

    try validate(grammar, director_sets);

    return .{
        .grammar = grammar,
        .director_sets = director_sets,
    };
}

pub fn parse(self: @This(), reader: Reader) AST {
    var stack = Vec.init();
    stack.push(END);
    stack.push(START);

    var output = Vec.init();

    while (true) {
        const top = stack.pop() orelse {
            return error.StackPoppedOut;
        };

        switch (top) {
            .non_term => {
                
            },
            .term => {
                const result = try reader.read(top);
                output.push(result);
            },
            .end => {
                 if (reader.end()) { break; }
                 else { return error.Remain; }
            },
        }
    }
}
