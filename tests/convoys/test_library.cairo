%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.factory import create_mint_convoy
from contracts.convoys.conveyables import Fungible
from contracts.convoys.conveyables.fungibles import Fungibles
from contracts.convoys.conveyables.fungibles.human import Human, human_balances
from contracts.convoys.library import (
    has_convoy,
    convoy_can_access,
    get_convoy_strength,
    get_convoy_protection,
    write_conveyables_to_arr,
    _get_conveyables,
    create_convoy,
    bind_convoy,
    unsafe_move_convoy,
    burn_convoy,
    unbind_convoy,
)
from contracts.eykar import get_convoys, move_convoy, get_conveyables

@view
func test_create_mint{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (convoy_id1) = create_mint_convoy(123, 0, 0);
    let (convoys_len, convoys) = get_convoys(0, 0);
    assert convoys_len = 1;
    assert [convoys] = convoy_id1;
    let (convoy_id2) = create_mint_convoy(3783, 0, 0);
    let (convoys_len, convoys) = get_convoys(0, 0);
    assert convoys_len = 2;
    assert [convoys] = convoy_id1;
    assert [convoys + 1] = convoy_id2;

    return ();
}

@view
func test_has_convoy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (convoy_id_1) = create_mint_convoy(123, 1, -3);
    let (convoy_id_2) = create_mint_convoy(123, 2, 5);
    let (convoy_id_3) = create_mint_convoy(123, 1, -3);

    let (convoys_len, convoys) = get_convoys(1, 0);
    assert convoys_len = 0;

    let (test) = has_convoy(convoy_id_1, 1, 0);
    assert test = FALSE;
    let (test) = has_convoy(convoy_id_1, 1, -3);
    assert test = TRUE;
    let (test) = has_convoy(convoy_id_2, 1, -3);
    assert test = FALSE;
    let (test) = has_convoy(convoy_id_3, 1, -3);
    assert test = TRUE;

    return ();
}

@view
func test_convoy_can_access{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (convoy_id) = create_mint_convoy(123, 17, -34);
    let (test) = convoy_can_access(convoy_id, 17, -34);
    assert test = TRUE;
    let (test) = convoy_can_access(convoy_id, 18, -35);
    assert test = TRUE;
    let (test) = convoy_can_access(convoy_id, 24, -35);
    assert test = FALSE;
    let (test) = convoy_can_access(convoy_id, -220, 3555);
    assert test = FALSE;
    let (test) = convoy_can_access(convoy_id, 16, -33);
    assert test = TRUE;
    return ();
}

@view
func test_get_convoy_strength{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (convoy_id) = create_mint_convoy(123, 2, -3);
    let (strength) = get_convoy_strength(convoy_id);
    assert strength = 10;
    return ();
}

@view
func test_get_convoy_protection{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (convoy_id) = create_mint_convoy(123, 2, -3);
    let (protection) = get_convoy_protection(convoy_id);
    assert protection = 10;
    return ();
}

@view
func test_get_conveyables{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (convoy_id) = create_mint_convoy(123, 2, -3);
    let (conveyables_len, conveyables) = _get_conveyables(convoy_id);
    assert conveyables_len = 1;
    let humans = [conveyables];
    assert humans.type = Human.type;
    assert humans.data = 10;
    return ();
}

@view
func test_write_conveyables_to_arr{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;
    let (convoy_id) = create_mint_convoy(123, 2, -3);
    let (conveyables: Fungible*) = alloc();
    let (conveyables_len) = write_conveyables_to_arr(convoy_id, 0, conveyables);
    assert conveyables_len = 1;
    assert [conveyables] = Fungible(Human.type, 10);
    return ();
}

@view
func test_create_convoy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    let (convoy_id) = create_convoy(123, 0);
    Fungibles.set(human_balances.addr, convoy_id, 27);
    bind_convoy(convoy_id, 3, 2);

    let (conveyables_len, conveyables) = get_conveyables(convoy_id);
    assert conveyables_len = 1;
    let humans = [conveyables];
    assert humans.type = Human.type;
    assert humans.data = 27;

    return ();
}

@view
func test_burn_convoy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    %{
        stop_prank_callable = start_prank(123)
        warp(0)
    %}
    let (convoy_id) = create_mint_convoy(123, 0, 0);
    burn_convoy(convoy_id);
    %{ warp(1) %}
    %{ expect_revert("TRANSACTION_FAILED") %}
    move_convoy(convoy_id, 0, 0, -10, 27);
    %{ stop_prank_callable() %}
    return ();
}

@view
func test_bind_convoy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    let (conveyables) = alloc();

    let (convoy_id) = create_convoy(123, 0);
    bind_convoy(convoy_id, -12, 11);
    let (convoys_len, convoys) = get_convoys(-12, 11);
    assert convoys_len = 1;
    assert [convoys] = convoy_id;

    let (convoy_id) = create_convoy(1234, 0);
    bind_convoy(convoy_id, -12, 11);
    let (convoys_len, convoys) = get_convoys(-12, 11);

    assert [convoys + 1] = convoy_id;

    return ();
}

@view
func test_unbind_convoy_first{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    let (conveyables) = alloc();

    let (convoy_id1) = create_convoy(123, 0);
    bind_convoy(convoy_id1, -12, 11);
    let (convoy_id2) = create_convoy(123, 0);
    bind_convoy(convoy_id2, -12, 11);
    let (convoys_len, convoys) = get_convoys(-12, 11);
    assert convoys_len = 2;
    assert convoys[0] = convoy_id1;
    assert convoys[1] = convoy_id2;

    let (res) = unbind_convoy(convoy_id1, -12, 11);
    assert res = TRUE;
    let (convoys_len, convoys) = get_convoys(-12, 11);
    assert convoys_len = 1;
    assert convoys[0] = convoy_id2;

    let (res) = unbind_convoy(convoy_id2, -12, 11);
    assert res = TRUE;
    let (convoys_len, convoys) = get_convoys(-12, 11);
    assert convoys_len = 0;

    return ();
}

@view
func test_unsafe_move_convoy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    let (convoy_id) = create_mint_convoy(123, 0, 0);
    unsafe_move_convoy(convoy_id, 0, 0, -10, 27);

    let (test) = has_convoy(convoy_id, 0, 0);
    assert test = FALSE;
    let (test) = has_convoy(convoy_id, -10, 27);
    assert test = TRUE;
    return ();
}

@view
func test_move_convoy_fail{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ stop_prank_callable = start_prank(123) %}
    let (convoy_id) = create_mint_convoy(123, 0, 0);
    %{ expect_revert("TRANSACTION_FAILED") %}
    move_convoy(convoy_id, 0, 0, -10, 27);
    %{ stop_prank_callable() %}
    return ();
}

@view
func test_move_convoy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    %{
        stop_prank_callable = start_prank(123)
        warp(0)
    %}
    let (convoy_id) = create_mint_convoy(123, 0, 0);
    %{ warp(1) %}
    move_convoy(convoy_id, 0, 0, -10, 27);
    let (test) = has_convoy(convoy_id, -10, 27);
    assert test = TRUE;
    %{ stop_prank_callable() %}
    return ();
}
