%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, abs_value
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.production import renewable_extraction, non_renew_extraction, get_alpha, get_k_modifier
from contracts.world import world

func get_cycles{range_check_ptr}(t: felt, l_h_t: felt, sqrt_alpha: felt) -> (cycles: felt):
    let (n, _) = unsigned_div_rem(t - l_h_t, 2 * sqrt_alpha)
    return (n)
end

func max_value{range_check_ptr}(alpha: felt, sqrt_alpha: felt) -> (max_value: felt):
    let (res, _)  = unsigned_div_rem(4 * sqrt_alpha, 5)
    return (res)
end

func renewable_production{range_check_ptr}(t: felt, x: felt, y: felt) -> (amount: felt):
    # Calculates current renewable resource production since last harvest.
    #
    # Parameters:
    #   t: harvest timestamp
    #   x: x-Coordinate of the plot
    #   y: y-Coordinate of the plot
    #
    # Returns:
    #   amount: number of resource produced
    alloc_locals
    # get alphas
    let (alpha, sqrt_alpha) = get_alpha(x, y)

    # calculate values for t and last_harvest times
    let (amount_t) = renewable_extraction(t, alpha, sqrt_alpha)
    #let (amount_l_h) = renewable_extraction(l_h_t, alpha, sqrt_alpha)

    # calculate how many cycles have passed -> n
    #let (n) = get_cycles(t, l_h_t, sqrt_alpha)
    # if n > 1 calculate max value else return calculated values
    #if n == FALSE:
    #    let (max_value) = max_value(alpha, sqrt_alpha)
    #    return () # (first_amount + max_value * n + last_amount)
    #else:
    #    return ()
    #end
    return (1)
end

func non_renewable_production{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: felt, y: felt, t: felt
) -> (amout: felt):
    # Calculates current non-renewable resource production since last harvest.
    #
    # Parameters:
    #   t: harvest timestamp
    #   x: x-Coordinate of the plot
    #   y: y-Coordinate of the plot
    #
    # Returns:
    #   amount: number of resource produced
    alloc_locals
    let (k) = get_k_modifier(x, y)
    let (plot) = world.read(x, y)
    let (l_h_amount) = non_renew_extraction(plot.availability, k)
    let (t_amount) = non_renew_extraction(t, k)
    let (plot) = (owner=plot.owner, structure=plot.structure, availability=t)
    world.write(x, y, plot)
    let (res) = abs_value(l_h_amount - t_amount)
    return(res)
end