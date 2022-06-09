%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.convoys.conveyables import Conveyable
from starkware.cairo.common.alloc import alloc

func transform{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_ids_len : felt,
    convoy_ids : felt*,
    len_output_sizes : felt,
    output_sizes : felt*,
    content : Conveyable*,
) -> ():
    return ()
end

func compact_conveyables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    conveyables_len : felt, conveyables : Conveyable*
) -> (compacted_len : felt, compacted : Conveyable*):
    ret
end

func add_single{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    conveyable : Conveyable, conveyables_len : felt, conveyables : Conveyable*
) -> (added_len : felt, added : Conveyable*):
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
        return (conveyables_len + 1, conveyables + Conveyable.SIZE)
    else:
        let (amount, len_purified, purified) = extract_fungible(
            conveyable.type, conveyables_len, conveyables
        )
        assert purified[len_purified] = Conveyable(type=conveyable.type, data=amount + conveyable.data)
        return (len_purified + 1, purified)
    end
end

func extract_fungible{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    type : felt, len_conveyables : felt, conveyables : Conveyable*
) -> (amount : felt, len_purified : felt, purified : Conveyable*):
    # Extract this fungible from the Conveyables list
    #
    #   Parameters:
    #       type: The type of fungible to extract
    #       len_conveyables: The length of the Conveyables list
    #       conveyables: The Conveyables list
    #
    #   Returns:
    #       amount: The amount of fungible of the given type
    #       len_purified: The length of the purified Conveyables list
    #       purified: The purified Conveyables list
    if len_conveyables == 0:
        let (purified : Conveyable*) = alloc()
        return (0, 0, purified)
    else:
        let elt : Conveyable = conveyables[len_conveyables - 1]
        let (amount : felt, len_purified : felt, purified : Conveyable*) = extract_fungible(
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
