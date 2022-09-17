%lang starknet

from contracts.map.biomes import (
    get_elevation,
    get_temperature,
    assert_not_ocean,
    assert_jungle_or_forest,
)
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import abs_value

// P = 2 ** 251 + 17 * 2 ** 192 + 1

// for points numbers comparison: epsilon = 1x10^(-9)
const epsilon = 2305843009;

const FRACT_PART = 2 ** 61;
@view
func test_elevation{range_check_ptr}() {
    alloc_locals;
    let (elevation0) = get_elevation(0, 0);

    let (elevation) = get_elevation((-1303) * FRACT_PART, 650 * FRACT_PART);  // returns -0.04867122811634398 -> 8343699359066055255413743169021728222755157683917479070804348695041744387680186780140707914159.99288911912239104
    let a = abs_value(
        elevation - 3618502788666131213697322783095070105623107215331596699972979827924770103729
    );
    let res1 = is_le(a, epsilon);

    let (elevation) = get_elevation((-1432) * FRACT_PART, (-1197) * FRACT_PART);  // returns 0.023157744919186856 -> 53398124231060951.903478663885094912
    let a = abs_value(elevation - 53398124231060951);
    let res2 = is_le(a, epsilon);

    assert elevation0 = 0;
    assert res1 = TRUE;
    assert res2 = TRUE;
    return ();
}

@view
func test_temperature{range_check_ptr}() {
    alloc_locals;
    let (temperature0) = get_temperature(0, 0);

    let (temperature) = get_temperature((-1303) * FRACT_PART, 650 * FRACT_PART);  // returns  0.056223681866065 -> 129642983783120715.36353516453888
    let a = abs_value(temperature - 129642983783120715);
    let res1 = is_le(a, epsilon);

    let (temperature) = get_temperature((-1432) * FRACT_PART, (-1197) * FRACT_PART);  // returns 0.6128040411754339 -> 1413029914362274918.2169542954057728
    let a = abs_value(temperature - 1413029914362274918);
    let res2 = is_le(a, epsilon);

    assert temperature0 = 0;
    assert res1 = TRUE;
    assert res2 = TRUE;
    return ();
}

@view
func test_assert_jungle_or_forest{range_check_ptr}() {
    assert_jungle_or_forest(86, -55);
    assert_jungle_or_forest(-266, -369);
    assert_jungle_or_forest(-416, -827);

    %{ expect_revert(error_message="this plot elevation is too low for a forest/jungle") %}
    assert_jungle_or_forest(1308, 680);

    %{ expect_revert(error_message="this plot temperature is too high for a forest/jungle") %}
    assert_jungle_or_forest(1075, -1126);

    return ();
}

@view
func test_assert_not_ocean{range_check_ptr}() {
    assert_not_ocean(-693, 414);
    assert_not_ocean(-40, 612);
    assert_not_ocean(194, 779);

    %{ expect_revert(error_message="this plot elevation corresponds to an ocean plot") %}
    assert_not_ocean(36, 411);

    %{ expect_revert(error_message="this plot elevation corresponds to an ocean plot") %}
    assert_not_ocean(-36, 323);

    return ();
}
