%lang starknet

from contracts.map.biomes import get_elevation, get_temperature

@view
func test_elevation{range_check_ptr}():
    let (elevation) = get_elevation(0, 0)
    assert elevation = 0
    return ()
end

@view
func test_temperature{range_check_ptr}():
    let (temperature) = get_temperature(0, 0)
    assert temperature = 0
    return ()
end
