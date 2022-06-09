%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.conveyables import Conveyable
from contracts.convoys.transform import extract_fungible, add_single

@view
func test_extract_fungible{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    let (test : Conveyable*) = alloc()
    assert test[0] = Conveyable(type=1, data=10)
    assert test[1] = Conveyable(type=1, data=5)
    assert test[2] = Conveyable(type=2, data=3)
    let (amount : felt, len_purified : felt, purified : Conveyable*) = extract_fungible(1, 3, test)
    assert amount = 15
    assert len_purified = 1
    assert purified[0] = Conveyable(type=2, data=3)

    let (amount : felt, len_purified : felt, purified : Conveyable*) = extract_fungible(2, 3, test)
    assert amount = 3
    assert len_purified = 2

    return ()
end

@view
func test_add_single{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    let (test : Conveyable*) = alloc()
    assert test[0] = Conveyable(type=1, data=10)
    assert test[1] = Conveyable(type=2, data=3)

    let (added_len : felt, added : Conveyable*) = add_single(Conveyable(type=1, data=27), 2, test)
    assert added_len = 2
    assert added[0] = Conveyable(type=2, data=3)
    assert added[1] = Conveyable(type=1, data=37)

    return ()
end
