%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.convoys.conveyables.conveyables import Fungible

@storage_var
func offers(convoy_id: felt, index: felt) -> (fungible: Fungible) {
}

func create_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, convoy_id: felt, conveyables_len: felt, conveyables: Fungible*
) -> () {
    // todo: assert owner can spend the convoy
    _create_offer(convoy_id, conveyables_len, conveyables);
    // set convoy availability at -1 so owner can't spend it
    return ();
}

func _create_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    convoy_id: felt, conveyables_len: felt, conveyables: Fungible*
) -> () {
    if (fungibles_len == 0) {
        return ();
    }
    tempvar next_len = fungibles_len - 1;
    offers.write(convoy_id, next_len, fungible[next_len]);
    create_offer(convoy_id, next_len, fungibles);
    return ();
}

func remove_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    convoy_id: felt
) -> () {
    offers.write(convoy_id, 0, Fungible(0, 0));
    return ();
}

func accept_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spent_convoy_id: felt, received_convoy_id: felt
) -> () {
    // assert received_convoy = offers[received_convoy_id]

    // remove offers[received_convoy_id]
    // send spent_convoy_id to received_convoy.owner
    // send received_convoy_id to caller

    return ();
}
