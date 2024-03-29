%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.convoys.conveyables.fungibles import Fungibles
from starkware.cairo.common.alloc import alloc

@storage_var
func example(convoy_id: felt) -> (balance: felt) {
}

@view
func test_readwrite{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    Fungibles.set(example.addr, 1, 12345);
    let (amount) = Fungibles.amount(example.addr, 1);
    assert amount = 12345;
    return ();
}

@view
func test_copy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    Fungibles.set(example.addr, 1, 12345);
    Fungibles.set(example.addr, 2, 1);

    Fungibles.copy(example.addr, 2, 1);
    let (amount) = Fungibles.amount(example.addr, 1);
    assert amount = 12346;
    return ();
}
