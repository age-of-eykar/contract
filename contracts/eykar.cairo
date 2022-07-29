%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le, abs_value
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc

from contracts.map.world import Plot, world, Structure, world_update, assert_conquerable
from contracts.map.coordinates import spiral, get_distance
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
    get_convoy_protection,
    convoy_can_access,
    has_convoy,
    assert_can_spend_convoy,
    assert_can_move_convoy,
    unsafe_move_convoy,
    convoy_meta,
    ConvoyMeta,
    chained_convoys,
    _get_next_convoys,
    _get_conveyables,
    burn_convoy,
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
from contracts.combat import (
    defender_protection_modifier,
    perform_turns,
    kill_soldiers,
    copy_profits,
    assert_is_puppet_of,
)
from contracts.exploitation.harvesting import _harvest

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

# Convoys

@view
func get_convoy_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (meta : ConvoyMeta):
    # Returns the ConvoyMeta of a specific convoy
    #
    # Parameters:
    #       convoy_id : felt
    #
    #   Returns:
    #       meta : ConvoyMeta
    let (meta : ConvoyMeta) = convoy_meta.read(convoy_id)
    return (meta)
end

@view
func get_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt
) -> (convoys_id_len : felt, convoys_id : felt*):
    # Gets convoys located at a given location [tested: test_create_mint]
    #
    # Parameters:
    #       x : x coordinate of the location
    #       y : y coordinate of the location
    #
    #   Returns:
    #       convoys_id_len : length of the convoys_id array
    #       convoys_id : array of convoys_id

    let (id) = chained_convoys.read(x, y)
    return _get_next_convoys(id, x, y)
end

@view
func get_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (conveyables_len : felt, conveyables : Fungible*):
    # Gets the conveyables of a convoy [tested: test_get_conveyables]
    #
    # Parameters:
    #       convoy_id : convoy_id
    #
    #   Returns:
    #       conveyables_len : length of the fungible conveyables array
    #       conveyables : array of fungible conveyable_id
    return _get_conveyables(convoy_id)
end

@view
func contains_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> (contained : felt):
    # Checks if a convoy is located at a given location
    #
    # Parameters:
    #       x : x coordinate of the location
    #       y : y coordinate of the location
    #       convoy_id : convoy_id
    #
    #   Returns:
    #       contained : TRUE if the convoy is located at the location, FALSE otherwise
    return has_convoy(convoy_id, x, y)
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
    let (test) = has_convoy(convoy_id, x, y)
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

@external
func move_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, source_x : felt, source_y : felt, target_x : felt, target_y : felt
) -> ():
    # Moves the convoy to the location if caller is the owner
    #
    # Parameters:
    #       convoy_id (felt) : The convoy to move
    #       source_x (felt) : The x coordinate of the source location
    #       source_y (felt) : The y coordinate of the source location
    #       target_x (felt) : The x coordinate of the target location
    #       target_y (felt) : The y coordinate of the target location

    let (caller) = get_caller_address()
    assert_can_move_convoy(convoy_id, caller)
    unsafe_move_convoy(convoy_id, source_x, source_y, target_x, target_y)
    return ()
end

# Combat

@external
func attack{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    attacker : felt, target : felt, x : felt, y : felt
) -> ():
    # Attack target convoy with attacker convoy (which needs to belong to the caller)
    # targets needs to be part of attacker plot
    #
    # Parameters:
    #  attacker: The attacker's convoy
    #  target: The target's convoy
    #  x: The x coordinate of the target's convoy
    #  y: The y coordinate of the target's convoy

    alloc_locals
    let (caller) = get_caller_address()

    # assert attacker can be spent
    assert_can_spend_convoy(attacker, caller)

    # check attacker is on this plot
    let (test) = has_convoy(attacker, x, y)
    assert test = TRUE

    # assert target has arrived
    let (timestamp) = get_block_timestamp()
    let (meta_target : ConvoyMeta) = convoy_meta.read(target)
    assert_le(meta_target.availability, timestamp)

    # check target is on this plot
    let (test) = has_convoy(target, x, y)
    assert test = TRUE

    # find original stength and protection
    let (attacker_strength) = get_convoy_strength(attacker)
    let (attacker_protection) = get_convoy_protection(attacker)
    let (target_strength) = get_convoy_strength(target)
    let (target_protection) = get_convoy_protection(target)

    let (modified_target_protection) = defender_protection_modifier(target_protection)

    let (winner_id, loser_id, winner_protection) = perform_turns(
        attacker,
        attacker_strength,
        attacker_protection,
        target,
        target_strength,
        modified_target_protection,
    )

    local original_protection : felt
    if winner_id == attacker:
        assert original_protection = attacker_protection
    else:
        assert original_protection = modified_target_protection
    end
    copy_profits(loser_id, winner_id)
    kill_soldiers(winner_id, winner_protection, original_protection)
    burn_convoy(loser_id)

    return ()
end

# Harvesting

@external
func harvest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
):
    # Harvest the given owned location using the given convoy.
    #
    # Parameters:
    #  convoy_id (felt) : The convoy to use for harvesting
    #  x (felt) : The x coordinate of the location to harvest
    #  y (felt) : The y coordinate of the location to harvest

    # assert plot's colony belongs to caller

    let (plot : Plot) = world.read(x, y)
    let (colony : Colony) = find_redirected_colony(plot.owner)
    let (caller) = get_caller_address()
    assert colony.owner = caller
    _harvest(caller, convoy_id, x, y)

    return ()
end

@external
func harvest_puppet{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
):
    # Harvest the not owned but controled given location using the given convoy.
    #
    # Parameters:
    #  convoy_id (felt) : The convoy to use for harvesting
    #  x (felt) : The x coordinate of the location to harvest
    #  y (felt) : The y coordinate of the location to harvest

    # assert plot's colony is controled by caller

    alloc_locals
    let (plot : Plot) = world.read(x, y)
    let (colony : Colony) = find_redirected_colony(plot.owner)
    let (caller) = get_caller_address()
    assert_is_puppet_of(colony.redirection, caller)
    _harvest(caller, convoy_id, x, y)

    return ()
end
