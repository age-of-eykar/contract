%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.convoys.conveyables import Conveyable

@storage_var
func human_balances(convoy_id : felt) -> (balance : felt):
end

namespace Human:
    # human
    const type = 'human'

    func append_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt, conveyables_len : felt, conveyables : Conveyable*
    ) -> (conveyables_len : felt, conveyables : Conveyable*):
        # Append the meta data to the conveyables array if conveyable is part of the convoy
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #   conveyables_len: The length of the conveyables array
        #   conveyables: The conveyables array
        #
        # Returns:
        #   conveyables_len: The length of the conveyables array
        #   conveyables: The conveyables array
        let (amount) = human_balances.read(convoy_id)
        if amount == 0:
            return (conveyables_len, conveyables)
        else:
            assert [conveyables] = Conveyable(type, amount)
            return (conveyables_len + 1, conveyables + 2)
        end
    end

    func amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> (amount : felt):
        # Get amount of this conveyable in a convoy
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   The amount of this conveyable in the convoy
        let (amount) = human_balances.read(convoy_id)
        return (amount)
    end

    func speed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> (speed : felt):
        # Get the speed of a specific conveyable
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   The speed of this conveyable within convoy
        return (1)
    end

    func movability{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> (movability : felt):
        # Get the movability of a specific conveyable
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   The movability of this conveyable within convoy
        let (amount) = human_balances.read(convoy_id)
        return (amount * 1)
    end

    func strength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> (strength : felt):
        # Get the strength of a specific conveyable
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   The strength of this conveyable within convoy
        let (amount) = human_balances.read(convoy_id)
        return (amount * 1)
    end

    func protection{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> (protection : felt):
        # Get the protection of a specific conveyable
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   The protection of this conveyable within convoy
        let (amount) = human_balances.read(convoy_id)
        return (amount * 1)
    end

    func set{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt, amount : felt
    ) -> ():
        # Set a new conveyable amount to a convoy
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to create the conveyable in
        #   amount: The amount of the conveyable to create
        human_balances.write(convoy_id, amount)
        return ()
    end

    func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        source_id : felt, target_id : felt
    ) -> ():
        # Transfer a conveyable from one convoy to another
        #
        # Parameters:
        #   source_id: The ID of the convoy to transfer from
        #   target_id: The ID of the convoy to transfer to
        let (source_amount) = human_balances.read(source_id)
        let (target_amount) = human_balances.read(target_id)
        human_balances.write(source_id, 0)
        human_balances.write(target_id, target_amount + source_amount)
        return ()
    end

    func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> ():
        # Burn a conveyable
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to burn
        human_balances.write(convoy_id, 0)
        return ()
    end
end