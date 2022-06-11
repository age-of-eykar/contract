%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.conveyables import Conveyable
from contracts.convoys.conveyables.human import Human
from contracts.convoys.factory import create_mint_convoy
from contracts.convoys.transform import (
    transform,
    extract_fungible,
    add_single,
    to_conveyables,
    compact_conveyables,
    get_conveyables,
    assert_contained,
    assert_included,
)

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

@view
func test_compact_conveyables{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Conveyable*) = alloc()
    assert test[0] = Conveyable(type=1, data=10)
    assert test[1] = Conveyable(type=2, data=3)
    assert test[2] = Conveyable(type=1, data=20)
    assert test[3] = Conveyable(type=2, data=7)
    let (compacted_len, compacted) = compact_conveyables(4, test)
    assert compacted_len = 2
    assert compacted[0] = Conveyable(type=1, data=30)
    assert compacted[1] = Conveyable(type=2, data=10)

    return ()
end

@view
func test_assert_contained{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Conveyable*) = alloc()
    assert test[0] = Conveyable(type=1, data=10)
    assert test[1] = Conveyable(type=2, data=3)
    assert test[2] = Conveyable(type=1, data=20)
    assert test[3] = Conveyable(type=2, data=7)
    assert_contained(Conveyable(type=1, data=20), 4, test)
    %{ expect_revert("TRANSACTION_FAILED") %}
    assert_contained(Conveyable(type=3, data=20), 4, test)
    return ()
end

@view
func test_assert_included{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Conveyable*) = alloc()
    assert test[0] = Conveyable(type=1, data=10)
    assert test[1] = Conveyable(type=2, data=3)
    assert test[2] = Conveyable(type=1, data=20)
    assert test[3] = Conveyable(type=2, data=7)

    let (content : Conveyable*) = alloc()
    assert content[0] = Conveyable(type=1, data=20)
    assert content[1] = Conveyable(type=2, data=7)
    assert_included(2, content, 4, test)

    %{ expect_revert("TRANSACTION_FAILED") %}
    assert_included(4, test, 2, content)
    return ()
end

@view
func test_to_conveyables{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (convoy_1_id : felt) = create_mint_convoy(123, 0, 0)
    let (convoy_2_id : felt) = create_mint_convoy(123, 0, 0)
    let (ids_arr : felt*) = alloc()
    ids_arr[0] = convoy_1_id
    ids_arr[1] = convoy_2_id
    let (len_conveyables : felt, conveyables : Conveyable*) = to_conveyables(2, ids_arr)
    assert len_conveyables = 2
    return ()
end

@view
func test_transform{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    %{ stop_prank_callable = start_prank(123) %}
    let (convoy1_id) = create_mint_convoy(123, 0, 0)
    let (convoy2_id) = create_mint_convoy(123, 0, 0)

    let (arr : felt*) = alloc()
    assert arr[0] = convoy1_id
    assert arr[1] = convoy2_id

    let (output_sizes : felt*) = alloc()
    assert output_sizes[0] = 1
    assert output_sizes[1] = 1

    let (flat_array : Conveyable*) = alloc()
    assert flat_array[0] = Conveyable(Human.type, 5)
    assert flat_array[1] = Conveyable(Human.type, 15)

    let (convoy_ids_len : felt, convoy_ids : felt*) = transform(
        2, arr, 2, output_sizes, 2, flat_array
    )
    assert convoy_ids_len = 2
    let convoy_id1 = convoy_ids[0]

    let (conveyables1_len, conveyables1) = get_conveyables(convoy_id1)
    let convoy_id2 = convoy_ids[1]
    let (conveyables2_len, conveyables2) = get_conveyables(convoy_id2)
    assert conveyables2_len = 1

    %{ stop_prank_callable() %}

    return ()
end
