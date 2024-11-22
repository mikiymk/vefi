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
