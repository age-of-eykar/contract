%lang starknet

from contracts.buildings.production import renewable_extraction, non_renew_extraction

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

    assert extraction_1 = 1000
    assert extraction_2 = 6
    assert extraction_3 = 880
    assert extraction_4 = 75
    return ()
end