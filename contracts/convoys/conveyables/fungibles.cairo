%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.convoys.conveyables import Fungible
from contracts.utils.storage import Storage

namespace Fungibles {
    func append_meta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset,
        type: felt,
        convoy_id: felt,
        conveyables_len: felt,
        conveyables: Fungible*,
    ) -> (conveyables_len: felt) {
        // Append the meta data to the conveyables array if conveyable is part of the convoy
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   type: The type of the conveyable
        //   convoy_id: The ID of the convoy to check
        //   conveyables_len: The length of the conveyables array
        //   conveyables: The conveyables array
        //
        // Returns:
        //   conveyables_len: The new length of the conveyables array
        let (amount) = Fungibles.amount(storage_var, convoy_id);
        if (amount == 0) {
            return (conveyables_len,);
        } else {
            assert conveyables[conveyables_len] = Fungible(type, amount);
            return (conveyables_len + 1,);
        }
    }

    func amount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset, convoy_id: felt
    ) -> (amount: felt) {
        // Get amount of this conveyable in a convoy
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   convoy_id: The ID of the convoy to check
        //
        // Returns:
        //   The amount of this conveyable in the convoy
        let (amount) = Storage.read(storage_var, 1, new (convoy_id));
        return (amount,);
    }

    func set{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset, convoy_id: felt, amount: felt
    ) -> () {
        // Set a new conveyable amount to a convoy
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   convoy_id: The ID of the convoy to create the conveyable in
        //   amount: The amount of the conveyable to create
        Storage.write(storage_var, 1, new (convoy_id), amount);
        return ();
    }

    func add{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset, convoy_id: felt, amount: felt
    ) -> () {
        // Add a conveyable amount to the existing convoy amount
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   convoy_id: The ID of the convoy to create the conveyable in
        //   amount: The amount of the conveyable to add
        let (existing_amount) = Fungibles.amount(storage_var, convoy_id);
        Storage.write(storage_var, 1, new (convoy_id), existing_amount + amount);
        return ();
    }

    func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset, source_id: felt, target_id: felt
    ) -> () {
        // Transfer a conveyable from one convoy to another
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   source_id: The ID of the convoy to transfer from
        //   target_id: The ID of the convoy to transfer to
        let (source_amount) = Storage.read(storage_var, 1, new (source_id));
        let (target_amount) = Storage.read(storage_var, 1, new (target_id));
        Storage.write(storage_var, 1, new (source_id), 0);
        Storage.write(storage_var, 1, new (target_id), target_amount + source_amount);
        return ();
    }

    func copy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset, source_id: felt, target_id: felt
    ) -> () {
        // Copy a conveyable from one convoy to another
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   source_id: The ID of the convoy to transfer from
        //   target_id: The ID of the convoy to transfer
        alloc_locals;
        let (source_amount) = Storage.read(storage_var, 1, new (source_id));
        let (target_amount) = Storage.read(storage_var, 1, new (target_id));
        Storage.write(storage_var, 1, new (target_id), target_amount + source_amount);
        return ();
    }

    func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        storage_var: codeoffset, convoy_id: felt
    ) -> () {
        // Burn a conveyable
        //
        // Parameters:
        //   storage_var: The storage variable to use
        //   convoy_id: The ID of the convoy to burn
        Storage.write(storage_var, 1, new (convoy_id), 0);
        return ();
    }
}
