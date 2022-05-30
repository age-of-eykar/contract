%lang starknet

from contracts.map.simplex_noise import simplex_noise

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using these functions.

@view
func get_elevation{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    return simplex_noise(x, y, 3, 1152921504606846976, 27670116110564328)
end

@view
func get_temperature{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    return simplex_noise(x, y, 1, 2305843009213693952, 34587645138205408)
end