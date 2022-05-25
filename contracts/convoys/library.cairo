%lang starknet

# Here is how to transfer resources in space and time

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

struct ConvoyMeta:
    member owner : felt  # address
    member arrival : felt  # date
    member size : felt
end

#
# Getters
#
@view
func get_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt
) -> (convoys_id_len : felt, convoys_id : felt*):
    let (id) = chained_convoys.read(x, y)
    return _get_convoys(x, y, id)
end

func _get_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, convoy_id : felt
) -> (convoys_id_len : felt, convoys_id : felt*):
    if convoy_id == 0:
        let (convoys_id) = alloc()
        return (0, convoys_id)
    end
    let (next) = next_chained_convoy.read(convoy_id)
    let (convoys_id_len, convoys_id) = _get_convoys(x, y, next)
    assert convoys_id[convoys_id_len] = convoy_id
    return (convoys_id_len + 1, convoys_id)
end

@view
func contains_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, convoy_id : felt
) -> (contained : felt):
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

@view
func get_convoy_strength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (strength : felt):
    alloc_locals
    let (conveyables_len : felt, conveyables : felt*) = get_conveyables(convoy_id)
    # return _get_conveyables_strength(conveyables_len, conveyables)
    return (4)
end

func _get_conveyables_strength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    conveyables_len : felt, conveyables : felt*
) -> (strength : felt):
    if conveyables_len == 0:
        return (0)
    else:
        let conveyable_id = [conveyables]
        alloc_locals
        let (conveyable_strength) = _get_strength(conveyable_id)
        let (next_strength) = _get_conveyables_strength(conveyables_len - 1, conveyables + 1)
        return (conveyable_strength + next_strength)
    end
end

@view
func get_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (conveyables_len : felt, conveyables : felt*):
    alloc_locals
    let (conveyables) = alloc()
    let (meta) = convoy_meta.read(convoy_id)
    if meta.size == 0:
        return (meta.size, conveyables)
    end

    # Recursively add conveyable id from storage to the conveyables array
    _get_conveyables(convoy_id, 0, meta.size, conveyables)
    return (meta.size, conveyables)
end

func _get_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, index : felt, convoy_size : felt, conveyables : felt*
):
    if index == convoy_size:
        return ()
    end

    let (conveyable_id) = convoy_content.read(convoy_id, index)
    assert conveyables[index] = conveyable_id

    _get_conveyables(convoy_id, index + 1, convoy_size, conveyables)
    return ()
end

#
# Functions
#
func create_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, arrival : felt, conveyables_len : felt, conveyables : felt*
) -> (convoy_id : felt):
    alloc_locals
    let (convoy_id) = _reserve_convoy_id()
    let meta : ConvoyMeta = ConvoyMeta(owner=owner, arrival=arrival, size=conveyables_len)
    convoy_meta.write(convoy_id, meta)
    _write_conveyables(convoy_id, 0, conveyables_len, conveyables)
    return (convoy_id)
end

func bind_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> ():
    # Binds the convoy to the location
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

func move_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, source_x : felt, source_y : felt, target_x : felt, target_y : felt
) -> ():
    # todo
    #let (prev) = _find_previous_convoy(convoy_id, source_x, source_y)
    return ()
end

func _reserve_convoy_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    convoy_id : felt
):
    alloc_locals
    let (convoy_id) = free_convoy_id.read()
    free_convoy_id.write(convoy_id + 1)
    return (convoy_id)
end

func _write_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, index : felt, conveyables_len : felt, conveyables : felt*
) -> ():
    # Write a conveyable array to a convoy
    #
    #   Parameters:
    #       convoy_id (felt): The id of the convoy to write to
    #       index (felt): The index to start with (usually 0)
    #       conveyables_len (felt): The length of the conveyables array
    #       conveyables (felt*): The array of conveyables to write
    #
    if conveyables_len == index:
        return ()
    end
    convoy_content.write(convoy_id, index, conveyables[index])
    _write_conveyables(convoy_id, index + 1, conveyables_len, conveyables)
    return ()
end

func _reserve_conveyable_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (conveyable_id : felt):
    alloc_locals
    let (conveyable_id) = free_conveyable_id.read()
    free_conveyable_id.write(conveyable_id + 1)
    return (conveyable_id)
end

func _write_fungible_conveyable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    type : felt, amount : felt
) -> (conveyable_id : felt):
    alloc_locals
    let (conveyable_id) = _reserve_conveyable_id()
    conveyable_type.write(conveyable_id, type)
    conveyable_fungible_amount.write(conveyable_id, amount)
    return (conveyable_id)
end

#
# Storage
#

# convoys

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

# conveyables

@storage_var
func free_conveyable_id() -> (conveyable_id : felt):
end

@storage_var
func conveyable_type(conveyable_id) -> (conveyable_type : felt):
end

@storage_var
func conveyable_fungible_amount(conveyable_id) -> (amount : felt):
end

#
# Hardcoded
#

@view
func _get_movability(conveyable_type : felt) -> (movability : felt):
    # Returns the moving capacity of a conveyable
    # this can be negative (eg if the conveyable is a content and not a container)
    let (data_address) = get_label_location(movabilities)
    return (cast(data_address, felt*)[conveyable_type])

    movabilities:
    dw 1  # human
    dw -1  # food
    dw -2  # horse
    dw 5  # horseman
end

@view
func _get_speed(conveyable_type : felt) -> (movability : felt):
    # Returns the speed of a conveyable
    # -1 if the conveyable is not a vehicle
    let (data_address) = get_label_location(speed)
    return (cast(data_address, felt*)[conveyable_type])

    speed:
    dw 1  # human
    dw -1  # food
    dw -1  # horse
    dw 2  # horseman
end

@view
func _get_strength(conveyable_type : felt) -> (movability : felt):
    # Returns the strength of a conveyable
    # 0 if the conveyable doesn't have strength
    let (data_address) = get_label_location(food)
    return (cast(data_address, felt*)[conveyable_type])

    food:
    dw 1  # human
    dw 0  # food
    dw 0  # horse
    dw 2  # horseman
end

@view
func _get_protection(conveyable_type : felt) -> (movability : felt):
    # Returns the protection of a conveyable
    # 0 if the conveyable doesn't provide protection
    let (data_address) = get_label_location(food)
    return (cast(data_address, felt*)[conveyable_type])

    food:
    dw 1  # human
    dw 0  # food
    dw 1  # horse
    dw 2  # horseman
end
