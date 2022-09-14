%lang starknet

from contracts.map.simplex_noise import simplex_noise
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.bool import TRUE, FALSE

struct Biome:
    member MOUNTAIN : felt
    member ICE_MOUNTAIN : felt
    member FROZEN_LAND : felt
    member DESERT : felt
    member PLAIN : felt
    member COAST : felt
    member FOREST : felt
    member JUNGLE : felt
    member OCEAN : felt
    member ICEBERG : felt
    member FROZEN_OCEAN : felt
end
const FRACT_PART = 2 ** 61

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using this functions.
func get_elevation{range_check_ptr}(x : felt, y : felt) -> (res : felt):
    return simplex_noise(x, y, 3, 1152921504606846976, 27670116110564327)
end

# About units:
# Parameters and return values are float, represented by 64.61 floating point format
# So convertion must be done before and after using this functions.
func get_temperature{range_check_ptr}(x : felt, y : felt) -> (res : felt):
    return simplex_noise(x, y, 1, FRACT_PART, 34587645138205409)
end

func assert_jungle_or_forest{range_check_ptr}(x : felt, y : felt) -> ():
    # Assert that the plot's biome is jungle or forest
    #
    # Parameters:
    #   x: the x-Coordinate of the plot
    #   y: the y-Coordinate of the plot

    # 0.1 in 64x61 fixed point format
    const ONE_TENTH = 230584300921369395
    
    # 0.2 in 64x61 fixed point format
    const ONE_FIFTH = 461168601842738790

    # 0.7 in 64x61 fixed point format
    const SEVEN_TENTH = 1614090106449585766

    alloc_locals
    let x_frac = x * FRACT_PART
    let y_frac = y * FRACT_PART

    # condition: 0.2 < elevation <= 0.7
    let (elevation) = get_elevation(x_frac, y_frac)

    let (condition_1) = is_le(ONE_FIFTH, elevation)
    if condition_1 == FALSE:
        with_attr error_message("this plot elevation is too low for a forest/jungle"):
            assert 0 = 1
        end
    end

    let (condition_2) = is_le(elevation, SEVEN_TENTH)
    if condition_2 == FALSE:
        with_attr error_message("this plot elevation is too high for a forest/jungle"):
            assert 0 = 1
        end
    end

    # condition: 0.1 < temperature < 0.7
    let (temperature) = get_temperature(x_frac, y_frac)

    let (condition_3) = is_le(ONE_TENTH, temperature)
    if condition_3 == FALSE:
        with_attr error_message("this plot temperature is too low for a forest/jungle"):
            assert 0 = 1
        end
    end

    let (condition_4) = is_le(temperature, SEVEN_TENTH)
    if condition_4 == FALSE:
        with_attr error_message("this plot temperature is too high for a forest/jungle"):
            assert 0 = 1
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
    alloc_locals
    let x_frac = x * FRACT_PART
    let y_frac = y * FRACT_PART

    let (elevation) = get_elevation(x_frac, y_frac)
    let (condition_1) = is_nn(elevation)

    if condition_1 == FALSE:
        with_attr error_message("this plot elevation corresponds to an ocean plot"):
            assert 0 = 1
        end
    end
    return ()
end
