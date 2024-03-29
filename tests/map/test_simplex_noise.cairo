%lang starknet

from contracts.map.simplex_noise import noise, simplex_noise
from starkware.cairo.common.math_cmp import is_le

@view
func test_noise{range_check_ptr}() {
    alloc_locals;

    // epsilon = 1x10^(-8)
    let epsilon = 23058430092;

    // noise(-10000, -7462119) -> 0.4959406342108503
    let (noise1) = noise(
        3618502788666131213697322783095070105623107215331596676914661963998932500481,
        3618502788666131213697322783095070105623107215331579493498161985455172616193,
    );
    let res1 = is_le(noise1 - 1143561244380094848, epsilon);

    // noise(567, 95827) -> -0.8128435553996287
    let (noise2) = noise(1307412986224164470784, 220962018043920650338304);
    let res2 = is_le(
        noise2 - 3618502788666131213697322783095070105623107215331596699971217766506069382657,
        epsilon,
    );

    // noise(-98.66, 8642) -> 0.004392063622767544
    let (noise3) = noise(
        3618502788666131213697322783095070105623107215331596699745597584846848983041,
        19927095285624743133184,
    );
    let res3 = is_le(noise3 - 10127409200580312, epsilon);

    // noise(0, 0) -> 0
    let (noise4) = noise(0, 0);
    let res4 = is_le(noise4, epsilon);

    assert res1 = 1;
    assert res2 = 1;
    assert res3 = 1;
    assert res4 = 1;

    return ();
}

@view
func test_simplex_noise{range_check_ptr}() {
    alloc_locals;

    // epsilon = 1x10^(-8)
    let epsilon = 23058430092;

    // simplex_noise(-67, 23005, 3, 0.5, 0.005) -> 0.42959318557584736
    let (simplex1) = simplex_noise(
        3618502788666131213697322783095070105623107215331596699818600574518554525697,
        53045918426961029365760,
        3,
        1152921504606846976,
        11529215046068470,
    );
    let res1 = is_le(simplex1 - 990574443765908736, epsilon);

    // simplex_noise(0, 0, 4, 0.5, 0.02) -> 0
    let (simplex2) = simplex_noise(0, 0, 4, 1152921504606846976, 46116860184273880);

    // simplex_noise(5699, 13765, 1, 0.5, 0.012) -> -0.6522840681902581
    let (simplex3) = simplex_noise(
        13140999309508841832448, 31739929021826497249280, 1, 1152921504606846976, 27670116110564328
    );
    let res3 = is_le(
        simplex3 - 3618502788666131213697322783095070105623107215331596699971587991477214045441,
        epsilon,
    );

    // simplex_noise(-456, -33, 2, 0.5, 0.1) -> 0.08738782152875592
    let (simplex4) = simplex_noise(
        3618502788666131213697322783095070105623107215331596698921627643934427578369,
        3618502788666131213697322783095070105623107215331596699896999236831820120065,
        2,
        1152921504606846976,
        230584300921369408,
    );
    let res4 = is_le(simplex4 - 201502597362495776, epsilon);

    assert res1 = 1;
    assert simplex2 = 0;
    assert res3 = 1;
    assert res4 = 1;

    return ();
}
