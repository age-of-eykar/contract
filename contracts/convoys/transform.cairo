%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.convoys.conveyables import Fungible
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address
from contracts.convoys.library import (
    get_conveyables,
    write_conveyables_to_arr,
    write_conveyables,
    create_convoy,
    assert_can_spend_convoy,
)

@external
func transform{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_ids_len : felt,
    convoy_ids : felt*,
    output_sizes_len : felt,
    output_sizes : felt*,
    output_len : felt,
    output : Fungible*,
) -> (convoy_ids_len : felt, convoy_ids : felt*):
    alloc_locals
    # first we need to ensure that the transformation is valid
    let (caller) = get_caller_address()
    assert_can_spend_convoys(convoy_ids_len, convoy_ids, caller)
    let (local input_len, input) = to_conveyables(convoy_ids_len, convoy_ids)
    let (output_len_) = _sum(output_sizes_len, output_sizes)
    assert output_len_ = output_len
    assert input_len = output_len

    let (compacted_input_len, compacted_input) = compact_conveyables(input_len, input)
    let (compacted_output_len, compacted_output) = compact_conveyables(output_len, output)
    assert_included(compacted_input_len, compacted_input, compacted_output_len, compacted_output)

    # then we can transform the input to the output
    return write_convoys(output_sizes_len, output_sizes, output, caller)
end

func _sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    felt_list_len : felt, felt_list : felt*
) -> (sum : felt):
    if felt_list_len == 0:
        return (0)
    end
    let (rest) = _sum(felt_list_len - 1, felt_list)
    return (rest + felt_list[felt_list_len - 1])
end

func assert_can_spend_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_ids_len : felt, convoy_ids : felt*, spender : felt
) -> ():
    if convoy_ids_len == 0:
        return ()
    end
    assert_can_spend_convoy(convoy_ids[convoy_ids_len - 1], spender)
    return assert_can_spend_convoys(convoy_ids_len - 1, convoy_ids, spender)
end

func write_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len_output_sizes : felt, output_sizes : felt*, output : Fungible*, owner : felt
) -> (convoy_ids_len : felt, convoy_ids : felt*):
    # Create convoys with the given conveyables
    #
    #   Parameters:
    #     len_output_sizes: length of output_sizes
    #     output_sizes: sizes of the output convoys
    #     output: the output convoys
    let (timestamp) = get_block_timestamp()
    return _write_convoys(len_output_sizes, output_sizes, output, owner, timestamp)
end

func _write_convoys{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len_output_sizes : felt,
    output_sizes : felt*,
    output : Fungible*,
    owner : felt,
    timestamp : felt,
) -> (convoy_ids_len : felt, convoy_ids : felt*):
    if len_output_sizes == 0:
        let (convoy_ids) = alloc()
        return (0, convoy_ids)
    end
    let output_len = [output_sizes]
    alloc_locals
    let (local convoy_id) = create_convoy(owner, timestamp)
    let firstelt : felt = [output].data
    write_conveyables(convoy_id, output_len, output)
    let (convoy_ids_len, convoy_ids) = _write_convoys(
        len_output_sizes - 1,
        output_sizes + 1,
        output + output_len * Fungible.SIZE,
        owner,
        timestamp,
    )
    assert convoy_ids[convoy_ids_len] = convoy_id
    return (convoy_ids_len + 1, convoy_ids)
end

func to_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_ids_len : felt, convoy_ids : felt*
) -> (len_conveyables : felt, conveyables : Fungible*):
    # Gets the conveyables for the given convoy ids.
    #
    #   Parameters:
    #     convoy_ids_len: The length of the convoy ids.
    #     convoy_ids: The convoy ids.
    #
    #   Returns:
    #     len_conveyables: The length of the conveyables.
    #     conveyables: The conveyables.
    if convoy_ids_len == 0:
        let (conveyables : Fungible*) = alloc()
        return (0, conveyables)
    end
    alloc_locals
    let (len_rest, rest) = to_conveyables(convoy_ids_len - 1, convoy_ids)
    let (len_conveyables : felt) = write_conveyables_to_arr(
        convoy_ids[convoy_ids_len - 1], len_rest, rest
    )
    return (len_conveyables, rest)
end

func assert_included{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len_a : felt, a : Fungible*, len_b : felt, b : Fungible*
) -> ():
    # Assert that B includes A
    #
    #   Parameters:
    #     len: length of arrays
    #     a: array of Fungible objects
    #     b: array of Fungible objects
    if len_a == 0:
        return ()
    end
    assert_contained(a[len_a - 1], len_b, b)
    return assert_included(len_a - 1, a, len_b, b)
end

func assert_contained{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    conveyable : Fungible, array_len : felt, array : Fungible*
) -> ():
    # Assert that the array contains the given Fungible
    #
    #   Parameters:
    #     conveyable: Fungible object
    #     array_len: length of array
    #     array: array of Fungible objects
    if array_len == 0:
        with_attr error_message("incorrect array inclusion"):
            assert 1 = 0
        end
    end
    let current = array[array_len - 1]
    if current.type == conveyable.type:
        if current.data == conveyable.data:
            return ()
        end
    end
    return assert_contained(conveyable, array_len - 1, array)
end

func compact_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    conveyables_len : felt, conveyables : Fungible*
) -> (compacted_len : felt, compacted : Fungible*):
    # Compact the conveyables array into an array without duplication
    #
    #   Parameters:
    #     conveyables_len: length of conveyables array
    #     conveyables: array of conveyables
    #
    #   Returns:
    #     compacted_len: length of compacted array
    #     compacted: array of compacted conveyables
    if conveyables_len == 0:
        let (compacted : Fungible*) = alloc()
        return (0, compacted)
    else:
        let (rest_len, rest) = compact_conveyables(conveyables_len - 1, conveyables)
        let (compacted_len : felt, compacted : Fungible*) = add_single(
            conveyables[conveyables_len - 1], rest_len, rest
        )
        return (compacted_len, compacted)
    end
end

func add_single{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    conveyable : Fungible, conveyables_len : felt, conveyables : Fungible*
) -> (added_len : felt, added : Fungible*):
    # Add the conveyable to the list of conveyables and merge conveyables of same type
    #
    #   Parameters:
    #       conveyable: the conveyable to add
    #       conveyables_len: the length of the conveyables array
    #       conveyables: the conveyables array (pointer at the start)
    #
    #   Returns:
    #       added_len: the length of the added conveyables array
    #       added: the added conveyables array (pointer at the end)

    # change this condition for non fungible resources support
    if conveyable.type == -1:
        assert conveyables[conveyables_len] = conveyable
        return (conveyables_len + 1, conveyables + Fungible.SIZE)
    else:
        let (amount, len_purified, purified) = extract_fungible(
            conveyable.type, conveyables_len, conveyables
        )
        assert purified[len_purified] = Fungible(type=conveyable.type, data=amount + conveyable.data)
        return (len_purified + 1, purified)
    end
end

func extract_fungible{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    type : felt, len_conveyables : felt, conveyables : Fungible*
) -> (amount : felt, len_purified : felt, purified : Fungible*):
    # Extract this fungible from the Fungibles list
    #
    #   Parameters:
    #       type: The type of fungible to extract
    #       len_conveyables: The length of the Fungibles list
    #       conveyables: The Fungibles list
    #
    #   Returns:
    #       amount: The amount of fungible of the given type
    #       len_purified: The length of the purified Fungibles list
    #       purified: The purified Fungibles list
    if len_conveyables == 0:
        let (purified : Fungible*) = alloc()
        return (0, 0, purified)
    else:
        let elt : Fungible = conveyables[len_conveyables - 1]
        let (amount : felt, len_purified : felt, purified : Fungible*) = extract_fungible(
            type, len_conveyables - 1, conveyables
        )
        if elt.type == type:
            return (elt.data + amount, len_purified, purified)
        else:
            assert purified[len_purified] = elt
            return (amount, len_purified + 1, purified)
        end
    end
end
