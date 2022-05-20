%lang starknet
%builtins pedersen range_check

# Here is how to transfer resources in space and time

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc

#
# Getters
#
@view
func get_convoyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt
) -> (convoyables_len : felt, convoyables : felt*):
    alloc_locals
    let (convoyables) = alloc()
    let (convoy_len) = convoy_size.read(convoy_id)
    if convoy_len == 0:
        return (convoy_len, convoyables)
    end

    # Recursively add convoyable id from storage to the convoyables array
    _get_convoyables(convoy_id, 0, convoy_len, convoyables)
    return (convoy_len, convoyables)
end

func _get_convoyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, index : felt, convoy_size : felt, convoyables : felt*
):
    if convoy_id == convoy_size:
        return ()
    end

    let (convoyable_id) = convoy_content.read(convoy_id, index)
    assert convoyables[index] = convoyable_id

    _get_convoyables(convoy_id, index + 1, convoy_size, convoyables)
    return ()
end

#
# Functions
#
func create_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoyables_len : felt, convoyables : felt*
) -> (convoy_id : felt):
    alloc_locals
    let (convoy_id) = _reserve_convoy_id()
    convoy_size.write(convoy_id, convoyables_len)
    return (convoy_id)
end

func _reserve_convoy_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    convoy_id : felt
):
    alloc_locals
    let (convoy_id) = free_convoy_id.read()
    free_convoy_id.write(convoy_id + 1)
    return (convoy_id)
end

func _write_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, index : felt, convoyables_len : felt, convoyables : felt*
) -> ():
    # Write a convoyable array to a convoy
    #
    #   Parameters:
    #       convoy_id (felt): The id of the convoy to write to
    #       index (felt): The index to start with (usually 0)
    #       convoyables_len (felt): The length of the convoyables array
    #       convoyables (felt*): The array of convoyables to write
    #
    if convoyables_len == 0:
        return ()
    end
    convoy_content.write(convoy_id, index, convoyables[index])
    _write_convoy(convoy_id, index + 1, convoyables_len, convoyables)
    return ()
end

func _reserve_convoyable_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (convoyable_id : felt):
    alloc_locals
    let (convoyable_id) = free_convoyable_id.read()
    free_convoyable_id.write(convoyable_id + 1)
    return (convoyable_id)
end

func _write_fungible_convoyable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    type : felt, amount : felt
) -> (convoyable_id : felt):
    alloc_locals
    let (convoyable_id) = _reserve_convoyable_id()
    convoyable_type.write(convoyable_id, type)
    convoyable_fungible_amount.write(convoyable_id, amount)
    return (convoyable_id)
end

#
# Storage
#

# convoys

@storage_var
func free_convoy_id() -> (convoy_id : felt):
end

@storage_var
func convoy_size(convoy_id) -> (size : felt):
end

@storage_var
func convoy_content(convoy_id, index) -> (convoyable_id : felt):
end

# convoyables

@storage_var
func free_convoyable_id() -> (convoyable_id : felt):
end

@storage_var
func convoyable_type(convoyable_id) -> (convoyable_type : felt):
end

@storage_var
func convoyable_fungible_amount(convoyable_id) -> (amount : felt):
end

#
# Hardcoded
#

func get_movability(convoyable_type : felt) -> (movability : felt):
    # Returns the moving capacity of a convoyable
    # this can be negative (eg if the convoyable is a content and not a container)
    let (data_address) = get_label_location(movabilities)
    return (cast(data_address, felt*)[convoyable_type])

    movabilities:
    dw 1  # human
    dw -1  # food
    dw -2  # horse
    dw 5  # horseman
end

func get_speed(convoyable_type : felt) -> (movability : felt):
    # Returns the speed of a convoyable
    # -1 if the convoyable is not a vehicle
    let (data_address) = get_label_location(speed)
    return (cast(data_address, felt*)[convoyable_type])

    speed:
    dw 1  # human
    dw -1  # food
    dw -1  # horse
    dw 2  # horseman
end
