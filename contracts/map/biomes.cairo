%lang starknet

from contracts.map.simplex_noise import simplex_noise
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.bool import TRUE, FALSE

const FRACT_PART = 2 ** 61

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using this functions.
func get_elevation{range_check_ptr}(x : felt, y : felt) -> (res : felt):
    return simplex_noise(x, y, 3, 1152921504606846976, 27670116110564328)
end

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using this functions.
func get_temperature{range_check_ptr}(x : felt, y : felt) -> (res : felt):
    return simplex_noise(x, y, 1, 2305843009213693952, 34587645138205408)
end

func assert_jungle_or_forest{range_check_ptr}(x : felt, y : felt) -> ():
    # Assert that the plot's biome is jungle or forest
    #
    # Parameters:
    #   x: the x-Coordinate of the plot
    #   y: the y-Coordinate of the plot
    #
    # 0.1 in 64x61 fixed point format
    const ONE = 230584300921369408
    alloc_locals
    let x_frac = x * FRACT_PART
    let y_frac = y * FRACT_PART

    # condition: 0.2 < elevation <= 0.7
    let (elevation) = get_elevation(x_frac, y_frac)

    # 0.2 = ONE/5 = 461168601842738816.61 => 461168601842738817 <= elevation
    let (condition_1) = is_le(461168601842738817, elevation)
    if condition_1 == FALSE:
        with_attr error_message("this plot elevation is too low for a forest/jungle"):
            assert 1 = 0
        end
    end

    # 0.7 = ONE*0.7 = 1614090106449585766.4 => elevation <= 1614090106449585766
    let (condition_2) = is_le(elevation, 1614090106449585766)
    if condition_2 == FALSE:
        with_attr error_message("this plot elevation is too high for a forest/jungle"):
            assert 1 = 0
        end
    end

    # condition: 0.1 < temperature < 0.7
    let (temperature) = get_temperature(x_frac, y_frac)

    # 0.1 = ONE/10 = 23058430092136940.8 => 23058430092136941 <= elevation
    let (condition_1) = is_le(23058430092136941, elevation)
    if condition_1 == FALSE:
        with_attr error_message("this plot temperature is too low for a forest/jungle"):
            assert 1 = 0
        end
    end

    # 0.7 = ONE*0.7 = 161409010644958585.6 => elevation <= 161409010644958585
    let (condition_2) = is_le(elevation, 1614090106449585766)
    if condition_2 == FALSE:
        with_attr error_message("this plot temperature is too high for a forest/jungle"):
            assert 1 = 0
        end
    end

    return ()
end

func assert_not_ocean{range_check_ptr}(x : felt, y : felt) -> ():
    # Assert that the plot's biome is not an ocean (used for minting)
    #
    # Parameters:
    #   x: the x-Coordinate of the plot
    #   y: the y-Coordinate of the plot
    #
    # 0.1 in 64x61 fixed point format
    alloc_locals
    let x_frac = x * FRACT_PART
    let y_frac = y * FRACT_PART

    let (elevation) = get_elevation(x_frac, y_frac)
    let (condition_1) = is_nn(elevation)
    if condition_1 == FALSE:
        with_attr error_message("this plot elevation corresponds to an ocean plot"):
            assert 1 = 0
        end
    end
    return ()
end
