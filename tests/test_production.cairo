%lang starknet

from contracts.production import renewable_extraction, non_renew_extraction, get_alpha
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE

@view
func test_renewable_extraction{range_check_ptr}():
    alloc_locals
    let (extraction_1) = renewable_extraction(345, 49, 7)
    let (extraction_2) = renewable_extraction(766666, 100, 10)
    let (extraction_3) = renewable_extraction(3, 121, 11)
    let (extraction_4) = renewable_extraction(999999999, 1000000, 1000)

    assert extraction_1 = 5
    assert extraction_2 = 0
    assert extraction_3 = 1
    assert extraction_4 = 402

    return ()
end

@view
func test_non_renewable_extraction{range_check_ptr}():
    alloc_locals
    let (extraction_1) = non_renew_extraction(407, 1000)
    let (extraction_2) = non_renew_extraction(4750, 776)
    let (extraction_3) = non_renew_extraction(1240, 970)
    let (extraction_4) = non_renew_extraction(420, 200)

    assert extraction_1 = 999
    assert extraction_2 = 6
    assert extraction_3 = 883
    assert extraction_4 = 65
    return ()
end

@view
func test_get_alpha{range_check_ptr}():
    alloc_locals
    let (alpha, _) = get_alpha(545, 50)
    let (res1_a) = is_le(alpha, 4000000)
    let (res1_b) = is_le(1000000, alpha)

    let (alpha, _) = get_alpha(755, -33)
    let (res2_a) = is_le(alpha, 4000000)
    let (res2_b) = is_le(1000000, alpha)

    let (alpha, _) = get_alpha(1000, -281)
    let (res3_a) = is_le(alpha, 4000000)
    let (res3_b) = is_le(1000000, alpha)

    let (alpha1, _) = get_alpha(1231, -381)
    let (alpha2, _) = get_alpha(2016, 1281)
    let (res_4) = is_le(alpha1, alpha2)
    let (res_5) = is_le(alpha, alpha2)

    assert res1_a = TRUE
    assert res1_b = TRUE
    assert res2_a = TRUE
    assert res2_b = TRUE
    assert res3_a = TRUE
    assert res3_b = TRUE
    # todo : fix function ! it's wrong !
    #assert alpha2 = 10
    #assert res_4 = TRUE
    #assert res_5 = TRUE

    return ()
end