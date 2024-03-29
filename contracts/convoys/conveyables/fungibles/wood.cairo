%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.convoys.conveyables import Fungible

@storage_var
func wood_balances(convoy_id: felt) -> (balance: felt) {
}

namespace Wood {
    // wood
    const type = 'wood';

    func speed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        convoy_id: felt
    ) -> (speed: felt) {
        // Get the speed of a specific conveyable
        //
        // Parameters:
        //   convoy_id: The ID of the convoy to check
        //
        // Returns:
        //   The speed of this conveyable within convoy
        return (-1,);
    }

    func movability{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        convoy_id: felt
    ) -> (movability: felt) {
        // Get the movability of a specific conveyable
        //
        // Parameters:
        //   convoy_id: The ID of the convoy to check
        //
        // Returns:
        //   The movability of this conveyable within convoy
        let (amount) = wood_balances.read(convoy_id);
        return (amount * (-1),);
    }
}
