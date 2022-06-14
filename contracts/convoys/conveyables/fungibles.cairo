%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.utils.storage import Storage

namespace Fungibles:
    func amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, convoy_id : felt
    ) -> (amount : felt):
        # Get amount of this conveyable in a convoy
        #
        # Parameters:
        #   storage_var: The storage variable to use
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   The amount of this conveyable in the convoy
        let (amount) = Storage.read(storage_var, 1, new (convoy_id))
        return (amount)
    end

    func set{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, convoy_id : felt, amount : felt
    ) -> ():
        # Set a new conveyable amount to a convoy
        #
        # Parameters:
        #   storage_var: The storage variable to use
        #   convoy_id: The ID of the convoy to create the conveyable in
        #   amount: The amount of the conveyable to create
        Storage.write(storage_var, 1, new (convoy_id), amount)
        return ()
    end

    func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, source_id : felt, target_id : felt
    ) -> ():
        # Transfer a conveyable from one convoy to another
        #
        # Parameters:
        #   storage_var: The storage variable to use
        #   source_id: The ID of the convoy to transfer from
        #   target_id: The ID of the convoy to transfer to
        let (source_amount) = Storage.read(storage_var, 1, cast(new (source_id), felt*))
        let (target_amount) = Storage.read(storage_var, 1, cast(new (target_id), felt*))
        Storage.write(storage_var, 1, new (source_id), 0)
        Storage.write(storage_var, 1, new (target_id), target_amount + source_amount)
        return ()
    end

    func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, convoy_id : felt
    ) -> ():
        # Burn a conveyable
        #
        # Parameters:
        #   storage_var: The storage variable to use
        #   convoy_id: The ID of the convoy to burn
        Storage.write(storage_var, 1, new (convoy_id), 0)
        return ()
    end
end
