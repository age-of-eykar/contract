%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.convoys.library import assert_can_spend_convoy, get_convoy_strength
from starkware.cairo.common.math import assert_le

struct Plot:
    member owner : felt
    member structure : felt
    member availability : felt
    member stored : felt
end

struct Structure:
    member NONE : felt
    member SETTLER_CAMP : felt
    member LUMBER_CAMP : felt
    member BARRACKS : felt
    member TOWN : felt
end

@storage_var
func world(x : felt, y : felt) -> (plot : Plot):
end

@event
func world_update(x : felt, y : felt):
end

func assert_conquerable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt, required_strength : felt, caller : felt
) -> ():
    # Asserts that the plot is conquerable by caller
    #
    # Parameters:
    #     convoy_id (felt): The id of the convoy
    #     x (felt): The x coordinate of the plot
    #     y (felt): The y coordinate of the plot
    #     required_strength (felt): The required strength
    #

    # Ensure the plot is not already owned
    let (plot : Plot) = world.read(x, y)
    assert plot.owner = 0

    # check caller is convoy owner
    # Check if the convoy is ready to be used
    assert_can_spend_convoy(convoy_id, caller)

    # Check convoy strength is enough
    let (strength : felt) = get_convoy_strength(convoy_id)
    assert_le(required_strength, strength)

    return ()
end
