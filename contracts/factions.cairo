%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_not_equal, assert_le
from contracts.convoys.conveyables.fungibles.soldier import Soldier
from contracts.convoys.conveyables.fungibles.human import human_balances
from contracts.convoys.conveyables.fungibles.wood import wood_balances
from contracts.utils.cairo_math_64x61.math64x61 import Math64x61
from contracts.colonies import Colony, colonies
from contracts.map.biomes import Biome, get_biome
//from contracts.eykar import get_prestige

struct Faction {
    NONE: felt,
    WARLORDS: felt,
    MERCHANTS: felt,
    DIPLOMATS: felt,
}

@storage_var
func factions(player: felt) -> (faction: felt) {
}

func join_warlords{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, army_id: felt, nb_buildings: felt, nb_military_buildings: felt
) {
    alloc_locals;
    //let prestige = get_prestige(player);
    //assert_le(100, prestige);
    with_attr error_message("not enough soldiers in the convoy") {
        let (soldier_strength) = Soldier.strength(army_id);
        let enough_soldiers = is_le(15000, soldier_strength);
        assert enough_soldiers = TRUE;
    }
    assert_enough_buildings(nb_military_buildings, nb_buildings, 4);
    factions.write(player, Faction.WARLORDS);
    return ();
}

func join_merchants{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, storage_id: felt, nb_buildings: felt, nb_resource_buildings: felt
) {
    alloc_locals;
    //let prestige = get_prestige(player);
    //assert_le(100, prestige);
    with_attr error_message("not enough wood in the convoy") {
        let (wood_amount) = wood_balances.read(storage_id);
        let enough_wood = is_le(5000, wood_amount);
        assert enough_wood = TRUE;
    }
    with_attr error_message("not enough human in the convoy") {
        let (human_amount) = human_balances.read(storage_id);
        let enough_human = is_le(5000, human_amount);
        assert enough_human = TRUE;
    }
    assert_enough_buildings(nb_resource_buildings, nb_buildings, 6);
    factions.write(player, Faction.MERCHANTS);
    return ();
}

func assert_enough_buildings{range_check_ptr}(nb_building: felt, total_building: felt, needed: felt) {
    with_attr error_message("not enough specialized buildings") {
        let ratio = Math64x61.div(nb_building * Math64x61.ONE, total_building * Math64x61.ONE);
        let needed_ratio = Math64x61.div(needed * Math64x61.ONE, 7 * Math64x61.ONE);
        let enough_buildings = is_le(needed_ratio, ratio);
        assert enough_buildings = TRUE;
    }
    return ();
}

func join_diplomats{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, colony_id_1: felt, colony_id_2: felt, colony_id_3: felt
) {
    alloc_locals;
    //let prestige = get_prestige(player);
    //assert_le(100, prestige);
    with_attr error_message("the colonies must be different") {
        assert_not_equal(colony_id_1, colony_id_2);
        assert_not_equal(colony_id_1, colony_id_3);
        assert_not_equal(colony_id_2, colony_id_3);
    }
    let (C1: Colony) = colonies.read(colony_id_1);
    let (C2: Colony) = colonies.read(colony_id_2);
    let (C3: Colony) = colonies.read(colony_id_3);
    with_attr error_message("the colonies must be valid") {
        assert player = C1.owner;
        assert player = C2.owner;
        assert player = C3.owner;
    }
    let (B1) = get_biome(C1.x, C1.y);
    let (B2) = get_biome(C2.x, C2.y);
    let (B3) = get_biome(C3.x, C3.y);
    with_attr error_message("the colonies must be on different biomes") {
        assert_not_equal(B1, B2);
        assert_not_equal(B1, B3);
        assert_not_equal(B2, B3);
    }
    with_attr error_message("colonies must be at least 7 plots big") {
        let good_size_1 = is_le(7, C1.plots_amount);
        assert good_size_1 = TRUE;
        let good_size_2 = is_le(7, C2.plots_amount);
        assert good_size_1 = TRUE;
        let good_size_3 = is_le(7, C3.plots_amount);
        assert good_size_1 = TRUE;
    }
    factions.write(player, Faction.DIPLOMATS);
    return ();
}

func quit_faction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(player: felt) {
    factions.write(player, Faction.NONE);
    return ();
}