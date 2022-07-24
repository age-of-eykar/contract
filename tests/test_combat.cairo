%lang starknet

from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.factory import create_mint_convoy
from contracts.convoys.library import create_convoy, bind_convoy, ConvoyMeta
from contracts.convoys.conveyables.fungibles import Fungibles
from contracts.convoys.conveyables.fungibles.wood import Wood, wood_balances
from contracts.convoys.conveyables.fungibles.human import Human, human_balances
from contracts.convoys.conveyables.fungibles.soldier import Soldier, soldier_balances
from contracts.combat import (
    defender_protection_modifier,
    kill_soldiers,
    attack,
    copy_profits,
    assert_is_puppet_of,
)
from contracts.eykar import mint, get_convoy_meta

@view
func test_defender_protection_modifier{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    let (test) = defender_protection_modifier(0)
    assert test = 0

    let (test) = defender_protection_modifier(2)
    assert test = 15

    let (test) = defender_protection_modifier(100)
    assert test = 150

    let (test) = defender_protection_modifier(400)
    assert test = 400

    return ()
end

@view
func test_kill_soldiers{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (timestamp) = get_block_timestamp()
    let (convoy_id) = create_convoy(1, timestamp)

    Fungibles.set(wood_balances.addr, convoy_id, 15)
    Fungibles.set(human_balances.addr, convoy_id, 10)
    Fungibles.set(soldier_balances.addr, convoy_id, 25)

    let (amount) = Fungibles.amount(wood_balances.addr, convoy_id)
    assert amount = 15

    let (amount) = Fungibles.amount(human_balances.addr, convoy_id)
    assert amount = 10

    let (amount) = Fungibles.amount(soldier_balances.addr, convoy_id)
    assert amount = 25

    kill_soldiers(convoy_id, 95, 100)

    # wood should not change
    let (amount) = Fungibles.amount(wood_balances.addr, convoy_id)
    assert amount = 15

    let (amount) = Fungibles.amount(human_balances.addr, convoy_id)
    assert amount = 9

    let (amount) = Fungibles.amount(soldier_balances.addr, convoy_id)
    assert amount = 23

    return ()
end

@view
func test_copy_profits{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (timestamp) = get_block_timestamp()
    let (convoy1_id) = create_convoy(1, timestamp)

    Fungibles.set(wood_balances.addr, convoy1_id, 1)
    Fungibles.set(human_balances.addr, convoy1_id, 2)

    let (convoy2_id) = create_convoy(2, timestamp)
    Fungibles.set(wood_balances.addr, convoy2_id, 3)
    Fungibles.set(human_balances.addr, convoy2_id, 4)

    copy_profits(convoy2_id, convoy1_id)

    let (amount) = Fungibles.amount(wood_balances.addr, convoy1_id)
    assert amount = 4

    let (amount) = Fungibles.amount(human_balances.addr, convoy1_id)
    assert amount = 2

    return ()
end

@view
func test_attack{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    %{ stop_prank_callable = start_prank(123) %}
    let (timestamp) = get_block_timestamp()
    let (convoy1_id) = create_convoy(123, timestamp - 1)
    bind_convoy(convoy1_id, 5, 6)

    Fungibles.set(wood_balances.addr, convoy1_id, 15)
    Fungibles.set(human_balances.addr, convoy1_id, 10)
    Fungibles.set(soldier_balances.addr, convoy1_id, 25)

    let (convoy2_id) = create_convoy(1, timestamp - 1)
    bind_convoy(convoy2_id, 5, 6)

    Fungibles.set(wood_balances.addr, convoy2_id, 10)
    Fungibles.set(human_balances.addr, convoy2_id, 10)

    attack(convoy1_id, convoy2_id, 5, 6)

    let (amount) = Fungibles.amount(wood_balances.addr, convoy1_id)
    assert amount = 25

    let (amount) = Fungibles.amount(human_balances.addr, convoy1_id)
    assert amount = 10

    let (amount) = Fungibles.amount(soldier_balances.addr, convoy1_id)
    assert amount = 25

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_equal_attack{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    %{ warp(0) %}
    let (target) = create_mint_convoy(1, 0, 0)
    let (attacker) = create_mint_convoy(2, 0, 0)
    %{ stop_prank_callable = start_prank(2) %}
    %{ warp(1) %}
    attack(attacker, target, 0, 0)

    let (meta : ConvoyMeta) = get_convoy_meta(target)
    assert 1 = meta.owner
    let (amount) = Fungibles.amount(human_balances.addr, attacker)
    assert amount = 10

    let (meta : ConvoyMeta) = get_convoy_meta(attacker)
    assert meta.owner = 0

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_is_puppet_of{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ warp(0) %}
    alloc_locals
    %{ stop_prank_callable = start_prank(123) %}
    mint('hello')
    %{ stop_prank_callable() %}

    let (timestamp) = get_block_timestamp()
    let (attacker_convoy) = create_convoy(456, timestamp)
    Fungibles.set(soldier_balances.addr, attacker_convoy, 25)
    bind_convoy(attacker_convoy, 0, 0)

    %{ warp(1) %}

    assert_is_puppet_of(1, 456)

    %{ expect_revert("TRANSACTION_FAILED") %}

    let (attacker_convoy) = create_convoy(789, timestamp)
    Fungibles.set(soldier_balances.addr, attacker_convoy, 1)
    bind_convoy(attacker_convoy, 0, 0)
    assert_is_puppet_of(1, 789)

    return ()
end
