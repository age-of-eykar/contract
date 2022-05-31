%lang starknet

# Here is how to transfer resources in space and time

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le, assert_not_equal
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from contracts.convoys.conveyables.human import Human
from contracts.convoys.conveyables import Conveyable

struct ConvoyMeta:
    member owner : felt  # address
    member availability : felt  # date
end

#
# Getters
#
@view
func get_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt
) -> (convoys_id_len : felt, convoys_id : felt*):
    # Gets convoys located at a given location [tested: test_create_mint]
    #
    #   Parameters:
    #       x : x coordinate of the location
    #       y : y coordinate of the location
    #
    #   Returns:
    #       convoys_id_len : length of the convoys_id array
    #       convoys_id : array of convoys_id

    let (id) = chained_convoys.read(x, y)
    return _get_next_convoys(id, x, y)
end

func _get_next_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> (convoys_id_len : felt, convoys_id : felt*):
    if convoy_id == 0:
        let (convoys_id) = alloc()
        return (0, convoys_id)
    end
    let (next) = next_chained_convoy.read(convoy_id)
    let (convoys_id_len, convoys_id) = _get_next_convoys(next, x, y)
    assert convoys_id[convoys_id_len] = convoy_id
    return (convoys_id_len + 1, convoys_id)
end

@view
func contains_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> (contained : felt):
    # Checks if a convoy is located at a given location [tested: test_contains_convoy]
    #
    #   Parameters:
    #       x : x coordinate of the location
    #       y : y coordinate of the location
    #       convoy_id : convoy_id
    #
    #   Returns:
    #       contained : TRUE if the convoy is located at the location, FALSE otherwise
    let (found_id) = chained_convoys.read(x, y)
    return _contains_convoy(found_id, convoy_id)
end

func _contains_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_check : felt, to_find : felt
) -> (contained : felt):
    if to_check == to_find:
        return (TRUE)
    end
    if to_check == 0:
        return (FALSE)
    end
    let next_to_check : felt = next_chained_convoy.read(to_check)
    return _contains_convoy(next_to_check, to_find)
end

func convoy_can_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> (bool : felt):
    # Checks if a convoy can access a location [tested: test_convoy_can_access]
    #
    #   Parameters:
    #       convoy_id : convoy_id
    #       x : x coordinate of the location
    #       y : y coordinate of the location
    #
    #   Returns:
    #       bool : TRUE if the convoy can access the location, FALSE otherwise
    return _convoy_can_access(convoy_id, x, y, 2, 2)
end

func _convoy_can_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt, x_index : felt, y_index : felt
) -> (bool : felt):
    let (current) = contains_convoy(convoy_id, x + x_index, y + y_index)
    if current == TRUE:
        return (TRUE)
    end

    if y_index == -1:
        if x_index == -1:
            return (FALSE)
        end
        return _convoy_can_access(convoy_id, x, y, x_index - 1, 2)
    end

    return _convoy_can_access(convoy_id, x, y, x_index, y_index - 1)
end

@view
func get_convoy_strength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (strength : felt):
    # Gets the strength of a convoy [tested: test_get_convoy_strength]
    #
    #   Parameters:
    #       convoy_id : convoy_id
    #
    #   Returns:
    #       strength : strength of the convoy

    let (human_strength) = Human.strength(convoy_id)
    return (human_strength)
end

@view
func get_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (conveyables_len : felt, conveyables : Conveyable*):
    # Gets the conveyables of a convoy [tested: test_get_conveyables]
    #
    #   Parameters:
    #       convoy_id : convoy_id
    #
    #   Returns:
    #       conveyables_len : length of the fungible conveyables array
    #       conveyables : array of fungible conveyable_id
    alloc_locals
    let conveyables_len = 0
    let (conveyables : Conveyable*) = alloc()
    let (conveyables_len, conveyables) = Human.append_meta(convoy_id, conveyables_len, conveyables)

    return (conveyables_len, conveyables - conveyables_len * 2)
end

#
# Setters
#
@external
func move_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, source_x : felt, source_y : felt, target_x : felt, target_y : felt
) -> ():
    # Moves the convoy to the location if caller is the owner
    #
    #   Parameters:
    #       convoy_id (felt) : The convoy to move
    #       source_x (felt) : The x coordinate of the source location
    #       source_y (felt) : The y coordinate of the source location
    #       target_x (felt) : The x coordinate of the target location
    #       target_y (felt) : The y coordinate of the target location

    let (meta) = convoy_meta.read(convoy_id)
    let (caller) = get_caller_address()
    assert meta.owner = caller
    let (timestamp) = get_block_timestamp()
    # assert meta.availability < timestamp (not just <=)
    assert_le(meta.availability, timestamp)
    assert_not_equal(meta.availability, timestamp)
    unsafe_move_convoy(convoy_id, source_x, source_y, target_x, target_y)
    return ()
end

#
# Functions
#
func create_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, availability : felt
) -> (convoy_id : felt):
    # Creates a convoy [tested: test_create_convoy]
    #
    #   Parameters:
    #       owner (felt) : The owner of the convoy
    #       availability (felt) : The timestamp when the convoy is available
    #
    #   Returns:
    #       convoy_id (felt) : The convoy_id of the created convoy
    alloc_locals
    let (convoy_id) = _reserve_convoy_id()
    let meta : ConvoyMeta = ConvoyMeta(owner=owner, availability=availability)
    convoy_meta.write(convoy_id, meta)
    return (convoy_id)
end

func bind_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> ():
    # Binds the convoy to the location [tested: test_bind_convoy]
    # If the location is already bound, it will be chained
    #
    #   Parameters:
    #       convoy_id (felt) : The convoy to bind
    #       x (felt) : The x coordinate of the location
    #       y (felt) : The y coordinate of the location

    let (link : felt) = chained_convoys.read(x, y)
    next_chained_convoy.write(convoy_id, link)
    chained_convoys.write(x, y, convoy_id)
    return ()
end

func unsafe_move_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, source_x : felt, source_y : felt, target_x : felt, target_y : felt
) -> ():
    # Moves the convoy from source to target [tested: test_unsafe_move_convoy]
    #
    #   Parameters:
    #       convoy_id (felt) : The convoy to move
    #       source_x (felt) : The x coordinate of the source location
    #       source_y (felt) : The y coordinate of the source location
    #       target_x (felt) : The x coordinate of the target location
    #       target_y (felt) : The y coordinate of the target location

    alloc_locals
    let (link : felt) = chained_convoys.read(source_x, source_y)
    let (next) = next_chained_convoy.read(convoy_id)
    # If the convoy is the first convoy in the list, we need to update the source location
    if convoy_id == link:
        chained_convoys.write(source_x, source_y, next)
        # Else, we need to find the previous convoy and update its next
    else:
        # this will be an infinite loop if the convoy is not in the list
        let (prev) = _find_previous_convoy(convoy_id, link, source_x, source_y)
        next_chained_convoy.write(prev, next)
    end
    # TODO: update the convoy_meta availability
    bind_convoy(convoy_id, target_x, target_y)
    return ()
end

func _find_previous_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, link : felt, x : felt, y : felt
) -> (prev : felt):
    let (next : felt) = next_chained_convoy.read(link)
    if next == convoy_id:
        return (link)
    end
    return _find_previous_convoy(convoy_id, next, x, y)
end

func _reserve_convoy_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    convoy_id : felt
):
    alloc_locals
    let (convoy_id) = free_convoy_id.read()
    free_convoy_id.write(convoy_id + 1)
    return (convoy_id + 1)
end

#
# Storage
#

@storage_var
func free_convoy_id() -> (convoy_id : felt):
end

@storage_var
func convoy_meta(convoy_id : felt) -> (meta : ConvoyMeta):
end

@storage_var
func convoy_content(convoy_id : felt, index : felt) -> (conveyable_id : felt):
end

@storage_var
func chained_convoys(x : felt, y : felt) -> (convoy_id : felt):
end

@storage_var
func next_chained_convoy(convoy_id : felt) -> (next_convoy_id : felt):
end
