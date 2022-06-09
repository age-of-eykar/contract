%lang starknet

from starkware.cairo.common.math import unsigned_div_rem, abs_value, sqrt
from starkware.cairo.common.pow import pow
from starkware.cairo.common.math_cmp import is_nn
from contracts.fixed_point_numbers import Math64x61_div, Math64x61_toFelt
from contracts.map.biomes import get_temperature

# To learn more about Eykar resources and extraction see our wiki: (insert link)

func renewable_extraction{range_check_ptr}(t: felt, alpha: felt, sqrt_alpha: felt) -> (amount: felt):
    # Gives the plot renewable resource amount over time.
    #
    # Parameters:
    #   t: current timestamp
    #   alpha: amount modifier
    #   sqrt_alpha: sqrt(alpha)
    #
    # Returns:
    #   amount: resource amount at instant t
    alloc_locals
    let (_, t_reduced) = unsigned_div_rem(t, 2 * sqrt_alpha)
    let (temp) = pow(t_reduced-sqrt_alpha, 3)
    let (abs_temp) = abs_value(temp)
    let (temp_div_1, _) = unsigned_div_rem(abs_temp, alpha)
    let (temp_div_2, _) = unsigned_div_rem(3*sqrt_alpha, 5)

    let (temp) = is_nn(temp)
    if temp == 1:
        return (t_reduced - temp_div_1 - temp_div_2)
    else:
        return (t_reduced + temp_div_1 - temp_div_2)
    end
end

const FRACT_PART = 2 ** 61

func non_renew_extraction{range_check_ptr}(t: felt, K: felt) -> (amount: felt):
    # Gives the plot non renewable resource amount over time. Uses 64x61 fixed point format.
    #
    # Parameters:
    #   t: current timestamp (felt)
    #   K: initial amount (felt)
    #
    # Returns:
    #   amount: resource amount at instant t (felt)
    alloc_locals
    let (t_5) = pow(t, 5)
    let (K_5) = pow(K, 5)
    let (sqrt_t) = sqrt(t)
    let (temp) = Math64x61_div(t_5 * FRACT_PART, K_5 * sqrt_t * FRACT_PART)
    let (res) = Math64x61_div(K * FRACT_PART, FRACT_PART + temp)
    return Math64x61_toFelt(res)
end

func get_alpha{range_check_ptr}(x: felt, y: felt) -> (alpha: felt, sqrt_alpha: felt):
    # Compute alpha modifier for wood directly from coordinates, depending on elevation.
    # alpha = (1000 + (1 - |temperature - 0.4|)**2 * 1000)**2
    #
    # Parameters:
    #   x: x-coordinate of the plot
    #   y: y-coordinate of the plot
    #
    # Returns:
    #   alpha: the alpha modifier
    #   sqrt_alpha: sqrt(alpha)
    const FOUR_TENTH = 922337203685477632
    const THOUSAND = 2305843009213693952000
    let (temperature) = get_temperature(x * FRACT_PART, y * FRACT_PART)
    let (temp) = abs_value(FOUR_TENTH - temperature)
    let temp = temp * temp * THOUSAND + THOUSAND
    let (sqrt_alpha) = Math64x61_toFelt(temp)
    return (sqrt_alpha * sqrt_alpha, sqrt_alpha)
end