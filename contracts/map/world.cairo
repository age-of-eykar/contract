%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.convoys.library import assert_can_spend_convoy, get_convoy_strength
from starkware.cairo.common.math import assert_le

struct Plot {
    owner: felt,
    structure: felt,
    availability: felt,
    stored: felt,
}

struct Structure {
    NONE: felt,
    SETTLER_CAMP: felt,
    LUMBER_CAMP: felt,
    BARRACKS: felt,
    TOWN: felt,
}

@storage_var
func world(x: felt, y: felt) -> (plot: Plot) {
}

@event
func world_update(x: felt, y: felt) {
}

func assert_conquerable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    convoy_id: felt, x: felt, y: felt, required_strength: felt, caller: felt
) -> () {
    // Asserts that the plot is conquerable by caller
    //
    // Parameters:
    //     convoy_id (felt): The id of the convoy
    //     x (felt): The x coordinate of the plot
    //     y (felt): The y coordinate of the plot
    //     required_strength (felt): The required strength
    //

    // Ensure the plot is not already owned
    let (plot: Plot) = world.read(x, y);
    assert plot.owner = 0;

    // check caller is convoy owner
    // Check if the convoy is ready to be used
    assert_can_spend_convoy(convoy_id, caller);

    // Check convoy strength is enough
    let (strength: felt) = get_convoy_strength(convoy_id);
    assert_le(required_strength, strength);

    return ();
}
