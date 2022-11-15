%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.factions import factions, Faction, join_diplomats, join_merchants, join_warlords
from contracts.convoys.conveyables.fungibles.soldier import Soldier, soldier_balances
from contracts.convoys.conveyables.fungibles.wood import Wood, wood_balances
from contracts.convoys.conveyables.fungibles.human import Human, human_balances
from contracts.convoys.conveyables.fungibles import Fungibles
from contracts.convoys.library import create_convoy, bind_convoy, ConvoyMeta, unbind_convoy
from contracts.colonies import Colony, create_colony
from contracts.eykar import expand, conquer

@view
func test_join_warlords{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (timestamp) = get_block_timestamp();
    let (army_id_1) = create_convoy('player1', timestamp);
    Fungibles.set(soldier_balances.addr, army_id_1, 3000);
    join_warlords('player1', army_id_1, 4, 3);
    let (p1_faction) = factions.read('player1');
    assert p1_faction = Faction.WARLORDS;

    let (army_id_2) = create_convoy('player2', timestamp);
    Fungibles.set(soldier_balances.addr, army_id_2, 2500);
    %{ expect_revert(error_message="not enough soldiers in the convoy")%}
    join_warlords('player2', army_id_2, 4, 3);

    let (army_id_3) = create_convoy('player3', timestamp);
    Fungibles.set(soldier_balances.addr, army_id_3, 4000);
    %{ expect_revert(error_message="not enough specialized buildings")%}
    join_warlords('player3', army_id_3, 2, 1);

    return ();
}

@view
func test_join_merchants{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (timestamp) = get_block_timestamp();
    let (convoy1) = create_convoy('player1', timestamp);
    Fungibles.set(wood_balances.addr, convoy1, 5000);
    Fungibles.set(human_balances.addr, convoy1, 5000);
    join_merchants('player1', convoy1, 234, 233);

    let (convoy2) = create_convoy('player2', timestamp);
    Fungibles.set(wood_balances.addr, convoy2, 4999);
    Fungibles.set(human_balances.addr, convoy2, 6000);
    %{ expect_revert(error_message="not enough wood in the convoy")%}
    join_merchants('player2', convoy2, 7, 6);

    let (convoy3) = create_convoy('player3', timestamp);
    Fungibles.set(wood_balances.addr, convoy3, 6000);
    Fungibles.set(human_balances.addr, convoy3, 4);
    %{ expect_revert(error_message="not enough human in the convoy")%}
    join_merchants('player3', convoy3, 4662, 3996);

    let (convoy4) = create_convoy('player4', timestamp);
    Fungibles.set(wood_balances.addr, convoy4, 1000000);
    Fungibles.set(human_balances.addr, convoy4, 1000000);
    %{ expect_revert(error_message="not enough specialized buildings")%}
    join_merchants('player4', convoy4, 4, 3);

    return ();
}

@view
func test_join_diplomats{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (timestamp) = get_block_timestamp();
    %{ stop_prank_callable = start_prank(1) %}
    let (convoy_p1) = create_convoy(1, timestamp);
    Fungibles.set(soldier_balances.addr, convoy_p1, 2);
    // PoP 1 (133, 72) ; (132, 72) ; (132, 71) ; (133, 71) ; (131, 71) ; (130, 71) ; (130, 72)
    // bind_convoy(convoy_p1, 133, 72);
    // conquer(convoy_p1, 133, 72, 'c1');
    // expand(convoy_p1, 133, 72, 132, 72);
    // expand(convoy_p1, 132, 72, 133, 71);
    // expand(convoy_p1, 133, 71, 132, 71);
    // expand(convoy_p1, 132, 71, 131, 71);
    // expand(convoy_p1, 131, 71, 130, 71);
    // expand(convoy_p1, 131, 71, 130, 71);
    // unbind_convoy(convoy_p1, 130, 72);
    // // Pop 2 (150, 49) ; (149, 49) ; (150, 50) ; (151, 49) ; (151, 50) ; (151, 48) ; (149, 49)
    // bind_convoy(convoy_p1, 150, 49);
    // conquer(convoy_p1, 150, 49, 'c1');
    // expand(convoy_p1, 150, 49, 149, 49);
    // expand(convoy_p1, 149, 49, 133, 71);
    // expand(convoy_p1, 133, 71, 132, 71);
    // expand(convoy_p1, 132, 71, 131, 71);
    // expand(convoy_p1, 131, 71, 130, 71);
    // expand(convoy_p1, 131, 71, 130, 71);
    // unbind_convoy(convoy_p1, 130, 72);
    // // Pop 3 (164, 45) ; (164, 44) ; (165, 45) ; (165, 44) ; (163, 45) ; (163, 44) ; (163, 46)
    // bind_convoy(convoy_p1, 133, 72);
    // conquer(convoy_p1, 133, 72, 'c1');
    // expand(convoy_p1, 133, 72, 132, 72);
    // expand(convoy_p1, 133, 72, 133, 71);
    // expand(convoy_p1, 133, 71, 132, 71);
    // expand(convoy_p1, 132, 71, 131, 71);
    // expand(convoy_p1, 131, 71, 130, 71);
    // expand(convoy_p1, 131, 71, 130, 71);
    // unbind_convoy(convoy_p1, 130, 72);
    // %{ stop_prank_callable() %}

    // let (colony2) = create_colony('c2', 'player1', 150, 49);
    // let (colony3) = create_colony('c3', 'player1', 164, 45);

    // // joueur avec deux colonies pareilles
    // // PoP 1 (133, 72) ; (132, 72) ; (133, 72) ; (132, 71) ; (133, 71) ; (134, 72) ; (133, 73)
    // // Pop 2 (150, 49) ; (149, 49) ; (150, 50) ; (151, 49) ; (151, 50) ; (151, 48) ; (149, 49)
    // let (convoy_p3) = create_convoy('player3', timestamp);
    // let (colony1) = create_colony('c1', 'player3', 133, 72);
    // let (colony2) = create_colony('c2', 'player3', 150, 49);

    // // joueur avec des colonies sur un meme biome
    // // PoP 1 (133, 72) ; (132, 72) ; (133, 72) ; (132, 71) ; (133, 71) ; (134, 72) ; (133, 73)
    // // Pop 2 (150, 49) ; (149, 49) ; (150, 50) ; (151, 49) ; (151, 50) ; (151, 48) ; (149, 49)
    // // Pop 3 (1010, -1514) ; (1009, -1514) ; (1008, -1514) ; (1010, -1513) ; (1010, -1515) ; (1009, -1515) ; (1008, -1515)
    // let (convoy_p4) = create_convoy('player4', timestamp);
    // let (colony1) = create_colony('c1', 'player4', 133, 72);
    // let (colony2) = create_colony('c2', 'player4', 150, 49);
    // let (colony3) = create_colony('c3', 'player4', 1010, -1514);

    // // joueur avec une colonie petite
    // // PoP 1 (133, 72) ; (132, 72) ; (133, 72) ; (132, 71) ; (133, 71) ; (134, 72) ; (133, 73)
    // // Pop 2 (150, 49) ; (149, 49) ; (150, 50) ; (151, 49) ; (151, 50) ; (151, 48) ; (149, 49)
    // // Pop 3 (164, 45) ; (164, 44)
    // let (convoy_p5) = create_convoy('player5', timestamp);
    // let (colony1) = create_colony('c1', 'player5', 133, 72);
    // let (colony2) = create_colony('c2', 'player5', 150, 49);
    // let (colony3) = create_colony('c3', 'player5', 164, 45);
    return ();
}