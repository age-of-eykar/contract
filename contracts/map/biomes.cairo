%lang starknet

from contracts.map.simplex_noise import simplex_noise
from starkware.cairo.common.math_cmp import is_le

const FRACT_PART = 2 ** 61

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using this functions.
func get_elevation{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    return simplex_noise(x, y, 3, 1152921504606846976, 27670116110564328)
end

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using this functions.
func get_temperature{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    return simplex_noise(x, y, 1, 2305843009213693952, 34587645138205408)
end

func assert_jungle_or_forest{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    # Assert that the plot's biome is jungle or forest
    #
    # Parameters:
    #   x: the x-Coordinate of the plot
    #   y: the y-Coordinate of the plot
    #
    # Returns:
    #   res: 1 if the biome is jungle or forest else 0
    # 0.1 in 64x61 fixed point format
    const TENTH = 230584300921369408
    alloc_locals
    let x_frac = x * FRACT_PART
    let y_frac = y * FRACT_PART

    let (elevation) = get_elevation(x_frac, y_frac)
    let (condition_1) = is_le(elevation, TENTH)
    if condition_1 == 1:
        return (0)
    end

    let (temperature) = get_temperature(x_frac, y_frac)
    let (condition_2) = is_le(temperature, 2 * TENTH)
    if condition_2 == 1:
        return (0)
    else:
        return (1)
    end
end