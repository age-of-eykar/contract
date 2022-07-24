%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.conveyables import Fungible
from contracts.convoys.conveyables.fungibles.human import Human
from contracts.convoys.factory import create_mint_convoy
from contracts.convoys.library import contains_convoy
from contracts.eykar import transform
from contracts.convoys.transform import (
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
    let (test : Fungible*) = alloc()
    assert test[0] = Fungible(type=1, data=10)
    assert test[1] = Fungible(type=1, data=5)
    assert test[2] = Fungible(type=2, data=3)
    let (amount : felt, len_purified : felt, purified : Fungible*) = extract_fungible(1, 3, test)
    assert amount = 15
    assert len_purified = 1
    assert purified[0] = Fungible(type=2, data=3)

    let (amount : felt, len_purified : felt, purified : Fungible*) = extract_fungible(2, 3, test)
    assert amount = 3
    assert len_purified = 2

    return ()
end

@view
func test_add_single{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Fungible*) = alloc()
    assert test[0] = Fungible(type=1, data=10)
    assert test[1] = Fungible(type=2, data=3)

    let (added_len : felt, added : Fungible*) = add_single(Fungible(type=1, data=27), 2, test)
    assert added_len = 2
    assert added[0] = Fungible(type=2, data=3)
    assert added[1] = Fungible(type=1, data=37)

    return ()
end

@view
func test_compact_conveyables{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Fungible*) = alloc()
    assert test[0] = Fungible(type=1, data=10)
    assert test[1] = Fungible(type=2, data=3)
    assert test[2] = Fungible(type=1, data=20)
    assert test[3] = Fungible(type=2, data=7)
    let (compacted_len, compacted) = compact_conveyables(4, test)
    assert compacted_len = 2
    assert compacted[0] = Fungible(type=1, data=30)
    assert compacted[1] = Fungible(type=2, data=10)

    return ()
end

@view
func test_assert_contained{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Fungible*) = alloc()
    assert test[0] = Fungible(type=1, data=10)
    assert test[1] = Fungible(type=2, data=3)
    assert test[2] = Fungible(type=1, data=20)
    assert test[3] = Fungible(type=2, data=7)
    assert_contained(Fungible(type=1, data=20), 4, test)
    %{ expect_revert("TRANSACTION_FAILED") %}
    assert_contained(Fungible(type=3, data=20), 4, test)
    return ()
end

@view
func test_assert_included{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (test : Fungible*) = alloc()
    assert test[0] = Fungible(type=1, data=10)
    assert test[1] = Fungible(type=2, data=3)
    assert test[2] = Fungible(type=1, data=20)
    assert test[3] = Fungible(type=2, data=7)

    let (content : Fungible*) = alloc()
    assert content[0] = Fungible(type=1, data=20)
    assert content[1] = Fungible(type=2, data=7)
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
    let (len_conveyables : felt, conveyables : Fungible*) = to_conveyables(2, ids_arr)
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

    let (flat_array : Fungible*) = alloc()
    assert flat_array[0] = Fungible(Human.type, 5)
    assert flat_array[1] = Fungible(Human.type, 15)

    let (convoy_ids_len : felt, convoy_ids : felt*) = transform(
        2, arr, 2, output_sizes, 2, flat_array, 0, 0
    )
    assert convoy_ids_len = 2

    let convoy_id1 = convoy_ids[0]
    let (conveyables1_len, conveyables1) = get_conveyables(convoy_id1)
    assert conveyables1_len = 1

    let convoy_id2 = convoy_ids[1]
    let (conveyables2_len, conveyables2) = get_conveyables(convoy_id2)
    assert conveyables2_len = 1

    %{ stop_prank_callable() %}

    return ()
end

@view
func test_split_transform{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    %{ stop_prank_callable = start_prank(123) %}
    let (convoy_id) = create_mint_convoy(123, 0, 0)

    let (input_contained) = contains_convoy(convoy_id, 0, 0)
    assert input_contained = TRUE

    let (arr : felt*) = alloc()
    assert arr[0] = convoy_id

    let (output_sizes : felt*) = alloc()
    assert output_sizes[0] = 1
    assert output_sizes[1] = 1

    let (flat_array : Fungible*) = alloc()
    assert flat_array[0] = Fungible(Human.type, 8)
    assert flat_array[1] = Fungible(Human.type, 2)

    let (convoy_ids_len : felt, convoy_ids : felt*) = transform(
        1, arr, 2, output_sizes, 2, flat_array, 0, 0
    )

    let (input_contained) = contains_convoy(convoy_id, 0, 0)
    assert input_contained = FALSE

    assert convoy_ids_len = 2

    let convoy_id1 = convoy_ids[0]
    let (conveyables1_len, conveyables1) = get_conveyables(convoy_id1)
    assert conveyables1_len = 1
    let (output_contained) = contains_convoy(convoy_id1, 0, 0)
    assert output_contained = TRUE

    let convoy_id2 = convoy_ids[1]
    let (conveyables2_len, conveyables2) = get_conveyables(convoy_id2)
    assert conveyables2_len = 1
    let (output_contained) = contains_convoy(convoy_id2, 0, 0)
    assert output_contained = TRUE

    let (convoy_ids_len : felt, convoy_ids : felt*) = transform(
        2, new (convoy_id1, convoy_id2), 1, new (1), 1, new (Fungible(Human.type, 10)), 0, 0
    )

    %{ stop_prank_callable() %}

    return ()
end
