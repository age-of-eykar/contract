%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import unsigned_div_rem
from contracts.convoys.conveyables.fungibles.wood import Wood
from contracts.convoys.conveyables.fungibles.human import Human
from contracts.convoys.conveyables.fungibles.soldier import Soldier
from contracts.factions import Faction, factions

// a player can be a guild

@storage_var
func prestige_per_player(player: felt) -> (prestige: felt) {
}

func add_prestige{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, prestige: felt
) -> () {
    let (current_prestige) = prestige_per_player.read(player);
    prestige_per_player.write(player, current_prestige + prestige);
    return ();
}

func remove_prestige{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, prestige: felt
) -> () {
    let (current_prestige) = prestige_per_player.read(player);
    let lower = is_le(current_prestige, prestige);
    if (lower == TRUE) {
        prestige_per_player.write(player, 0);
    } else {
        prestige_per_player.write(player, current_prestige - prestige);
    }
    return ();
}

func reset_prestige{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt
) -> () {
    prestige_per_player.write(player, 0);
    return ();
}

func difficulty_modifier{}(conveyables: felt) -> (felt) {
    if (conveyables == Wood.type) {
        return (1,);
    }
    if (conveyables == Human.type) {
        return (1,);
    }
    if (conveyables == Soldier.type) {
        return (1,);
    }
    return (0,);
}

func harvest_prestige{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(player: felt, amount: felt, convoyable: felt) {
    let (mod_d) = difficulty_modifier(convoyable);
    let (player_faction) = factions.read(player);
    if (player_faction == Faction.MERCHANTS) {
        let (prestige_amount, _) = unsigned_div_rem(amount * mod_d, 100);
        add_prestige(player, prestige_amount);
    } else {
        let (prestige_amount, _) = unsigned_div_rem(amount * mod_d, 300);
        add_prestige(player, prestige_amount);
    }
    return ();
}