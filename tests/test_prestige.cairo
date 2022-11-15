%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from contracts.prestige import add_prestige, reset_prestige, remove_prestige, harvest_prestige
from contracts.eykar import get_prestige
from contracts.factions import factions, Faction

@view
func test_add_remove_reset_prestige{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (prestige) = get_prestige('thomas');
    assert prestige = 0;

    add_prestige('thomas', 5);
    let (prestige) = get_prestige('thomas');
    assert prestige = 5;

    add_prestige('thomas', 5);
    let (prestige) = get_prestige('thomas');
    assert prestige = 10;
    
    remove_prestige('thomas', 3);
    let (prestige) = get_prestige('thomas');
    assert prestige = 7;

    reset_prestige('thomas');
    let (prestige) = get_prestige('thomas');
    assert prestige = 0;

    remove_prestige('louis', 5);
    let (prestige) = get_prestige('louis');
    assert prestige = 0;

    return ();
}

@view
func test_harvest_prestige{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    reset_prestige('no_faction_player_1');
    reset_prestige('no_faction_player_2');
    reset_prestige('merchant');
    harvest_prestige('no_faction_player_1', 200, 'wood');
    let (prestige) = get_prestige('no_faction_player_1');
    assert prestige = 0;
    harvest_prestige('no_faction_player_2', 300, 'wood');
    let (prestige) = get_prestige('no_faction_player_2');
    assert prestige = 1;
    factions.write('merchant', Faction.MERCHANTS);
    harvest_prestige('merchant', 200, 'wood');
    let (prestige) = get_prestige('merchant');
    assert prestige = 2;
    return ();
}
