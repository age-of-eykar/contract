%lang starknet

from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.map.simplex_noise import simplex_noise
from contracts.utils.cairo_math_64x61.math64x61 import Math64x61

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

func lumbercamp_modifier{}(x : felt, y : felt) -> (modifier : felt):
    # Returns lumber camp production modifier.
    # For jungles:
    #   floor((t-0,1)*10+1)
    # For forests:
    #   floor(6*(e-0,2)+1)
    #
    # Parameters:
    #   x: the x-Coordinate of the plot
    #   y: the y-Coordinate of the plot

    # 0.1 in 64x61 fixed point format
    const ONE_TENTH = 230584300921369395

    # 0.2 in 64x61 fixed point format
    const ONE_FIFTH = 461168601842738790

    # 0.4 in 64x61 fixed point format
    const FOUR_TENTH = 922337203685477580

    let (temperature) = get_temperature(x_frac, y_frac)
    let (condition) = is_le(temperature, FOUR_TENTH)

    # if forest
    if condition:
        let (elevation) = get_elevation(x_frac, y_frac)
        return Math64x61.toFelt(6 * (elevation - ONE_FIFTH) + Math64x61.ONE)
    else # if jungle
        return Math64x61.toFelt((temperature - ONE_TENTH) * 10 + Math64x61.ONE)
    end
end

func extreme_biome_modfier{}(x : felt, y : felt) -> (modifier : felt):
    # Returns plot's extreme modifier.
    # Plain, Coast, Forest, Jungle  -> 1
    # Mountain, Frozen land         -> 2
    # Ice Mountain, Desert          -> 3
    #
    # Parameters:
    #   x: the x-Coordinate of the plot
    #   y: the y-Coordinate of the plot

    # 0.05 in 64x61 fixed point format
    const FIVE_HUNDREDTH = 115292150460684697

    # 0.7 in 64x61 fixed point format
    const SEVEN_TENTH = 1614090106449585766

    # 0.9 in 64x61 fixed point format
    const NINE_TENTH = 2075258708292324556

    alloc_locals
    let x_frac = x * FRACT_PART
    let y_frac = y * FRACT_PART

    let (elevation) = get_elevation(x_frac, y_frac)
    let (temperature) = get_temperature(x_frac, y_frac)

    # condition: 0,05 < elevation <= 0,7
    let (condition_1) = is_le(FIVE_HUNDREDTH, elevation)
    let (condition_2) = is_le(elevation, SEVEN_TENTH)
    if condition_1 and condition_2:
        # condition: temperature < -0,9
        let (condition) = is_le(temperature, -NINE_TENTH)
        if condition:
            # frozen lands
            return (2)
        end
        # condition: temperature > 0,7
        let (condition) = is_le(SEVEN_TENTH, temperature)
        if condition:
            # desert
            return (3)
        end
        return (1)
    end

    # condition: elevation > 0,7
    let (condition) = is_le(SEVEN_TENTH, elevation)
    if condition:
        # condition: temperature < -0,9
        let (condition) = is_le(temperature, NEG_NINE_TENTH)
        if condition:
            # ice mountain
            return(3)
        else
            # mountain
            return (2)
        end
    end
    # rest
    return (1)
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
