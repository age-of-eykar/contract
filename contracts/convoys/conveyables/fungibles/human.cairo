%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.convoys.conveyables import Fungible

@storage_var
func human_balances(convoy_id : felt) -> (balance : felt):
end

namespace Human:
    # human
    const type = 'human'

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
end
