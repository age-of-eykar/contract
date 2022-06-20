%lang starknet

from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.combat import defender_protection_modifier, kill_soldiers
from contracts.convoys.library import create_convoy, bind_convoy
from contracts.convoys.conveyables.fungibles import Fungibles
from contracts.convoys.conveyables.fungibles.wood import Wood, wood_balances
from contracts.convoys.conveyables.fungibles.human import Human, human_balances
from contracts.convoys.conveyables.fungibles.soldier import Soldier, soldier_balances

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
