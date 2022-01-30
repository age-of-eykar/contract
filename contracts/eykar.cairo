# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from contracts.coordinates import get_distance

struct Plot:
    member owner : felt
    member dateOfOwnership : felt
    member structure : felt
end

@storage_var
func world(x : felt, y : felt) -> (plot : Plot):
end

@storage_var
func current_registration_id() -> (plot : Plot):
end

@view
func get_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x : felt, y : felt) -> (plot : Plot):
    let (plot) = world.read(x, y)
    return (plot)
end

@external
func mint_colony{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end
