%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.factory import create_mint_convoy
from contracts.convoys.library import (
    get_convoys,
    contains_convoy,
    get_convoy_strength,
    get_conveyables,
    create_convoy,
    bind_convoy,
    unsafe_move_convoy,
    move_convoy,
    _write_fungible_conveyable,
)

@view
func test_create_mint{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (convoy_id1) = create_mint_convoy(123, 0, 0)
    let (convoys_len, convoys) = get_convoys(0, 0)
    assert convoys_len = 1
    assert [convoys] = convoy_id1

    let (convoy_id2) = create_mint_convoy(3783, 0, 0)
    let (convoys_len, convoys) = get_convoys(0, 0)
    assert convoys_len = 2
    assert [convoys] = convoy_id1
    assert [convoys + 1] = convoy_id2

    return ()
end

@view
func test_contains_convoy{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (convoy_id_1) = create_mint_convoy(123, 1, -3)
    let (convoy_id_2) = create_mint_convoy(123, 2, 5)
    let (convoy_id_3) = create_mint_convoy(123, 1, -3)

    let (convoys_len, convoys) = get_convoys(1, 0)
    assert convoys_len = 0

    let (test) = contains_convoy(1, 0, convoy_id_1)
    assert test = FALSE
    let (test) = contains_convoy(1, -3, convoy_id_1)
    assert test = TRUE
    let (test) = contains_convoy(1, -3, convoy_id_2)
    assert test = FALSE
    let (test) = contains_convoy(1, -3, convoy_id_3)
    assert test = TRUE

    return ()
end

@view
func test_get_convoy_strength{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (convoy_id) = create_mint_convoy(123, 2, -3)
    let (strength) = get_convoy_strength(convoy_id)
    assert strength = 10

    return ()
end

@view
func test_get_conveyables{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (convoy_id) = create_mint_convoy(123, 2, -3)
    let (conveyables_len, conveyables) = get_conveyables(convoy_id)
    assert conveyables_len = 1
    assert [conveyables] = 1

    let (convoy_id) = create_mint_convoy(123, 2, -3)
    let (conveyables_len, conveyables) = get_conveyables(convoy_id)
    assert conveyables_len = 1
    assert [conveyables] = 2
    return ()
end

@view
func test_create_convoy{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    let (conveyables) = alloc()

    let (conveyable_0) = _write_fungible_conveyable(1, 2)
    assert [conveyables] = conveyable_0
    let (conveyable_1) = _write_fungible_conveyable(2, 5)
    assert [conveyables + 1] = conveyable_1

    let (convoy_id) = create_convoy(123, 3, 2, conveyables)
    let (content_len, content) = get_conveyables(convoy_id)
    assert [content] = conveyable_0
    assert [content + 1] = conveyable_1
    return ()
end

@view
func test_bind_convoy{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    let (conveyables) = alloc()

    let (conveyable_0) = _write_fungible_conveyable(1, 2)
    assert [conveyables] = conveyable_0
    let (conveyable_1) = _write_fungible_conveyable(2, 5)
    assert [conveyables + 1] = conveyable_1

    let (convoy_id) = create_convoy(123, 3, 2, conveyables)
    bind_convoy(convoy_id, -12, 11)
    let (convoys_len, convoys) = get_convoys(-12, 11)
    assert convoys_len = 1
    assert [convoys] = convoy_id
    return ()
end

@view
func test_unsafe_move_convoy{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    let (convoy_id) = create_mint_convoy(123, 0, 0)
    unsafe_move_convoy(convoy_id, 0, 0, -10, 27)

    let (test) = contains_convoy(0, 0, convoy_id)
    assert test = FALSE
    let (test) = contains_convoy(-10, 27, convoy_id)
    assert test = TRUE
    return ()
end

@view
func test_move_convoy_fail{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ stop_prank_callable = start_prank(123) %}
    let (convoy_id) = create_mint_convoy(123, 0, 0)
    %{ expect_revert("TRANSACTION_FAILED") %}
    move_convoy(convoy_id, 0, 0, -10, 27)
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_move_convoy{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ 
    stop_prank_callable = start_prank(123)
    warp(0)
    %}
    let (convoy_id) = create_mint_convoy(123, 0, 0)
    %{ warp(1) %}
    move_convoy(convoy_id, 0, 0, -10, 27)
    %{ stop_prank_callable() %}
    return ()
end