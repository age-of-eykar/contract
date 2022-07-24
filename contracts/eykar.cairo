%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le, abs_value
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc

from contracts.world import (
    Plot,
    world,
    Structure,
    world_update,
    assert_conquerable,
)
from contracts.coordinates import spiral, get_distance
from contracts.colonies import (
    merge,
    Colony,
    colonies,
    create_colony,
    redirect_colony,
    find_redirected_colony,
    current_registration_id,
    add_colony_to_player,
    _get_next_available_plot,
    _get_player_colonies,
)
from contracts.convoys.library import (
    get_convoy_strength,
    convoy_can_access,
    contains_convoy,
    assert_can_spend_convoy,
    unsafe_move_convoy,
    convoy_meta,
    ConvoyMeta,
)
from contracts.utils.arrays import sum
from contracts.convoys.conveyables import Fungible
from contracts.convoys.transform import (
    assert_can_spend_convoys,
    to_conveyables,
    compact_conveyables,
    assert_included,
    unbind_convoys,
    write_convoys,
)
from contracts.convoys.factory import create_mint_convoy
from contracts.combat import attack

#
# VIEW FUNCTIONS
#

# Colonies

@view
func get_colony{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt) -> (
    colony : Colony
):
    # Gets the colony object after multiple redirections
    #
    # Parameters:
    #       id (felt): the colony id
    #
    #   Returns:
    #       colony (felt): struct after redirections
    return find_redirected_colony(id)
end

@view
func get_player_colonies{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player : felt
) -> (colonies_len : felt, colonies : felt*):
    let (colonies_len, found_colonies) = _get_player_colonies(player, 0)
    return (colonies_len, found_colonies - colonies_len)
end

#
# EXTERNAL FUNCTIONS
#

# World

@view
func get_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt
) -> (plot : Plot):
    # Gets a plot object at the given coordinates
    #
    # Parameters:
    #       x (felt): The x coordinate of the plot
    #       y (felt): The y coordinate of the plot
    #
    #   Returns:
    #       plot (Plot): The plot object at the given coordinates
    let (plot) = world.read(x, y)
    return (plot)
end

# Territory

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt):
    # Mints a plot on the next available location of the spawn spiral
    alloc_locals
    let (n) = current_registration_id.read()
    let (x, y, m) = _get_next_available_plot(n)
    current_registration_id.write(m + 1)

    let (player) = get_caller_address()
    let (colony_id) = merge(player, x, y)
    let (timestamp) = get_block_timestamp()
    if colony_id == 0:
        let (colony) = create_colony(name, player, x, y)
        add_colony_to_player(player, colony.redirection)
        world.write(
            x,
            y,
            Plot(owner=colony.redirection, structure=Structure.SETTLER_CAMP, availability=timestamp),
        )
    else:
        world.write(
            x, y, Plot(owner=colony_id, structure=Structure.SETTLER_CAMP, availability=timestamp)
        )
    end
    create_mint_convoy(player, x, y)
    world_update.emit(x, y)
    return ()
end

@external
func expand{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, source_x : felt, source_y : felt, target_x : felt, target_y : felt
):
    # Expands a colony using a convoy at destination
    #
    # Parameters:
    #     convoy_id (felt): The id of the convoy
    #     source_x (felt): The x coordinate of the plot to expand
    #     source_y (felt): The y coordinate of the plot to expand
    #     target_x (felt): The x coordinate of the plot to conquer
    #     target_y (felt): The y coordinate of the plot to conquer

    alloc_locals

    let (caller) = get_caller_address()

    # Check if the convoy is near the target
    let (found) = convoy_can_access(convoy_id, target_x, target_y)
    assert found = TRUE

    # check plot is conquerable
    assert_conquerable(convoy_id, target_x, target_y, 3, caller)

    # assert user owns source plot colony
    let (plot : Plot) = world.read(source_x, source_y)
    let colony_id : felt = plot.owner
    let (colony : Colony) = colonies.read(colony_id - 1)
    assert colony.owner = caller

    # move convoy from source to target (ensures the convoy is really on source)
    unsafe_move_convoy(convoy_id, source_x, source_y, target_x, target_y)

    # add plot to colony of source
    let (timestamp) = get_block_timestamp()
    world.write(target_x, target_y, Plot(owner=colony_id, structure=2, availability=timestamp))
    world_update.emit(target_x, target_y)
    return ()
end

@external
func conquer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt, name : felt
):
    # Conquers a plot using a convoy and create a new colony (or add the plot to an existing one)
    #
    # Parameters:
    #     convoy_id (felt): The id of the convoy
    #     x (felt): The x coordinate of the plot to conquer
    #     y (felt): The y coordinate of the plot to conquer
    #     name (felt): The name of the colony

    alloc_locals
    let (player) = get_caller_address()

    # check convoy is on this plot
    let (test) = contains_convoy(convoy_id, x, y)
    assert test = TRUE

    # check plot is conquerable
    assert_conquerable(convoy_id, x, y, 3, player)

    # create a new colony or add this plot to an existing colony
    let (colony_id) = merge(player, x, y)
    let (timestamp) = get_block_timestamp()
    if colony_id == 0:
        let (colony) = create_colony(name, player, x, y)
        add_colony_to_player(player, colony.redirection)
        world.write(
            x,
            y,
            Plot(owner=colony.redirection, structure=Structure.SETTLER_CAMP, availability=timestamp),
        )
    else:
        world.write(
            x, y, Plot(owner=colony_id, structure=Structure.SETTLER_CAMP, availability=timestamp)
        )
    end
    world_update.emit(x, y)
    return ()
end

# Convoys

@external
func transform{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_ids_len : felt,
    convoy_ids : felt*,
    output_sizes_len : felt,
    output_sizes : felt*,
    output_len : felt,
    output : Fungible*,
    x : felt,
    y : felt,
) -> (convoy_ids_len : felt, convoy_ids : felt*):
    alloc_locals
    # first we need to ensure that the transformation is valid
    let (caller) = get_caller_address()
    assert_can_spend_convoys(convoy_ids_len, convoy_ids, caller)
    let (local input_len, input) = to_conveyables(convoy_ids_len, convoy_ids)
    let (output_len_) = sum(output_sizes_len, output_sizes)
    assert output_len_ = output_len
    let (compacted_input_len, compacted_input) = compact_conveyables(input_len, input)
    let (compacted_output_len, compacted_output) = compact_conveyables(output_len, output)
    assert compacted_input_len = compacted_output_len
    assert_included(compacted_input_len, compacted_input, compacted_output_len, compacted_output)

    # we ensure that the location is valid and unbind the convoys
    unbind_convoys(convoy_ids_len, convoy_ids, x, y)

    # then we can transform the input to the output
    return write_convoys(output_sizes_len, output_sizes, output, caller, x, y)
end

