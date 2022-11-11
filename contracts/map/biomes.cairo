%lang starknet

from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.map.simplex_noise import simplex_noise
from contracts.utils.cairo_math_64x61.math64x61 import Math64x61

// CONST:
const FRACT_PART = 2 ** 61;

// 0.9 in 64x61 fixed point format
const NINE_TENTH        = 2075258708292324556;

// 0.85 in 64x61 fixed point format
const HEIGHT_HALF_TENTH = 1959966557831639859;

// 0.7 in 64x61 fixed point format
const SEVEN_TENTH       = 1614090106449585766;

// 0.4 in 64x61 fixed point format
const FOUR_TENTH        = 922337203685477580;

// 0.2 in 64x61 fixed point format
const ONE_FIFTH         = 461168601842738790;

// 0.1 in 64x61 fixed point format
const ONE_TENTH         = 230584300921369395;
       
// 0.05 in 64x61 fixed point format
const FIVE_HUNDREDTH    = 115292150460684697;

// todo: biomes struct
struct Biome {
    COAST: felt,
    ICEBERG: felt,
    FROZEN_OCEAN: felt,
    OCEAN: felt,
    ICE_MOUNTAIN: felt,
    MOUNTAIN: felt,
    FROZEN_LAND: felt,
    FOREST: felt,
    JUNGLE: felt,
    DESERT: felt,
    PLAIN: felt,
}

// About units:
// Parameters and return values are float, represented by 64.61 floating point format
// So convertion must be done before and after using this functions.
func get_elevation{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
    return simplex_noise(x, y, 3, 1152921504606846976, 27670116110564327);
}

// About units:
// Parameters and return values are float, represented by 64.61 floating point format
// So convertion must be done before and after using this functions.
func get_temperature{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
    return simplex_noise(x, y, 1, FRACT_PART, 34587645138205409);
}

func get_biome{range_check_ptr}(x: felt, y: felt) -> (felt) {
    alloc_locals;
    let x_frac = x * FRACT_PART;
    let y_frac = y * FRACT_PART;
    let (temperature) = get_temperature(x_frac, y_frac);
    let (elevation) = get_elevation(x_frac, y_frac);

    let pos_ele = is_nn(elevation);
    let coast_ele = is_le(elevation, FIVE_HUNDREDTH);
    if (pos_ele == TRUE and coast_ele == TRUE) {
        return (Biome.COAST,);
    }
    
    let neg_ele = is_le(elevation, 0);
    if (neg_ele == TRUE) {
        let min_temp = is_le(temperature, NINE_TENTH);
        if (min_temp == TRUE) {
            return (Biome.ICEBERG,);
        }
        let min_temp = is_le(temperature, HEIGHT_HALF_TENTH);
        if (min_temp == TRUE) {
            return (Biome.FROZEN_OCEAN,);
        }
        return (Biome.OCEAN,);
    }

    let max_ele = is_le(SEVEN_TENTH, elevation);
    if (max_ele == TRUE) {
        let min_temp = is_le(temperature, NINE_TENTH);
        if (min_temp == TRUE) {
            return (Biome.ICE_MOUNTAIN,);
        }
        return (Biome.MOUNTAIN,);
    }

    let min_temp = is_le(temperature, NINE_TENTH);
    if (min_temp == TRUE) {
        return (Biome.FROZEN_LAND,);
    }

    let mid_ele = is_le(ONE_FIFTH, elevation);
    let mid_temp = is_le(ONE_TENTH, temperature);
    if (mid_ele == TRUE and mid_temp == TRUE) {
        let temp = is_le(temperature, FOUR_TENTH);
        if (temp == TRUE) {
            return (Biome.FOREST,);
        }
        let temp = is_le(temperature, SEVEN_TENTH);
        if (temp == TRUE) {
            return (Biome.JUNGLE,);
        }
        let max_temp = is_le(SEVEN_TENTH, temperature);
        if (max_temp == TRUE) {
            return (Biome.DESERT,);
        }
        return (Biome.PLAIN,);
    }

    let max_temp = is_le(SEVEN_TENTH, temperature);
    if (max_temp == TRUE) {
        return (Biome.DESERT,);
    }
    return (Biome.PLAIN,);
}

func lumbercamp_modifier{range_check_ptr}(x: felt, y: felt) -> (modifier: felt) {
    // Returns lumber camp production modifier.
    // For jungles:
    //   floor((t-0,4)*10+1)
    // For forests:
    //   floor(6*(e-0,2)+1)
    //
    // Parameters:
    //   x: the x-Coordinate of the plot
    //   y: the y-Coordinate of the plot

    alloc_locals;
    let x_frac = x * FRACT_PART;
    let y_frac = y * FRACT_PART;
    let (temperature) = get_temperature(x_frac, y_frac);
    let condition = is_le(temperature, FOUR_TENTH);

    // if forest
    if (condition == TRUE) {
        let (elevation) = get_elevation(x_frac, y_frac);
        return (modifier=Math64x61.toFelt(6 * (elevation - ONE_FIFTH) + Math64x61.ONE),);
    
    // if jungle
    } else {
        return (modifier=Math64x61.toFelt((temperature - FOUR_TENTH) * 10 + Math64x61.ONE),);
    }
}

func extreme_biome_modfier{range_check_ptr}(x: felt, y: felt) -> (modifier: felt) {
    // Returns plot's extreme modifier.
    // Plain, Coast                   -> 1
    // Forest, jungle                 -> 2
    // Frozen land, Mountain, Desert  -> 3
    // Ice Mountain                   -> 4
    //
    // Parameters:
    //   x: the x-Coordinate of the plot
    //   y: the y-Coordinate of the plot

    alloc_locals;
    let x_frac = x * FRACT_PART;
    let y_frac = y * FRACT_PART;

    let (elevation) = get_elevation(x_frac, y_frac);
    let (temperature) = get_temperature(x_frac, y_frac);

    // condition: elevation >= 0
    let condition = is_le(0, elevation);
    if (condition == TRUE) {
        // condition: elevation > 0.7
        let condition = is_le(elevation, SEVEN_TENTH);
        if (condition == FALSE) {
            // condition: temperature < -0.9
            let condition = is_le(-NINE_TENTH, temperature);
            if (condition == FALSE) {
                return (4,);
            } else {
                return (3,);
            }
        }

        // condition: temperature < -0.9
        let condition = is_le(-NINE_TENTH, temperature);
        if (condition == FALSE) {
            return (3,);
        }

        // condition: elevation > 0.2 and temperature > 0.1
        let condition_1 = is_le(elevation, ONE_FIFTH);
        let condition_2 = is_le(temperature, ONE_TENTH);
        if (condition_1 == FALSE and condition_2 == FALSE) {
            return (2,);
        }

        // condition: temperature > 0.7
        let condition = is_le(temperature, SEVEN_TENTH);
        if (condition == FALSE) {
            return (3,);
        }

        return (1,);
    } else {
        return (0,);   
    }
}

func assert_jungle_or_forest{range_check_ptr}(x: felt, y: felt) -> () {
    // Assert that the plot's biome is jungle or forest
    //
    // Parameters:
    //   x: the x-Coordinate of the plot
    //   y: the y-Coordinate of the plot

    alloc_locals;
    let x_frac = x * FRACT_PART;
    let y_frac = y * FRACT_PART;

    // condition: 0.2 < elevation <= 0.7
    let (elevation) = get_elevation(x_frac, y_frac);

    let condition_1 = is_le(ONE_FIFTH, elevation);
    if (condition_1 == FALSE) {
        with_attr error_message("this plot elevation is too low for a forest/jungle") {
            assert 0 = 1;
        }
    }

    let condition_2 = is_le(elevation, SEVEN_TENTH);
    if (condition_2 == FALSE) {
        with_attr error_message("this plot elevation is too high for a forest/jungle") {
            assert 0 = 1;
        }
    }

    // condition: 0.1 < temperature < 0.7
    let (temperature) = get_temperature(x_frac, y_frac);

    let condition_3 = is_le(ONE_TENTH, temperature);
    if (condition_3 == FALSE) {
        with_attr error_message("this plot temperature is too low for a forest/jungle") {
            assert 0 = 1;
        }
    }

    let condition_4 = is_le(temperature, SEVEN_TENTH);
    if (condition_4 == FALSE) {
        with_attr error_message("this plot temperature is too high for a forest/jungle") {
            assert 0 = 1;
        }
    }

    return ();
}

func assert_not_ocean{range_check_ptr}(x: felt, y: felt) -> () {
    // Assert that the plot's biome is not an ocean (used for minting)
    //
    // Parameters:
    //   x: the x-Coordinate of the plot
    //   y: the y-Coordinate of the plot
    alloc_locals;
    let x_frac = x * FRACT_PART;
    let y_frac = y * FRACT_PART;

    let (elevation) = get_elevation(x_frac, y_frac);
    let condition_1 = is_nn(elevation);

    if (condition_1 == FALSE) {
        with_attr error_message("this plot elevation corresponds to an ocean plot") {
            assert 0 = 1;
        }
    }
    return ();
}
