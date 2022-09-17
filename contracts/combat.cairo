%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from contracts.convoys.conveyables.fungibles import Fungibles
from contracts.convoys.conveyables.fungibles.wood import Wood, wood_balances
from contracts.convoys.conveyables.fungibles.human import Human, human_balances
from contracts.convoys.conveyables.fungibles.soldier import Soldier, soldier_balances
from contracts.convoys.library import (
    get_convoy_strength,
    get_convoy_protection,
    assert_can_spend_convoy,
    can_spend_convoy,
    has_convoy,
    chained_convoys,
    _get_next_convoys,
    burn_convoy,
    convoy_meta,
    ConvoyMeta,
)
from contracts.colonies import Colony, find_redirected_colony

func defender_protection_modifier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    defender_protection: felt
) -> (modified_protection: felt) {
    // Modify the defender's protection to give a bonus to small defenders and a malus to big defenders
    //
    // Parameters:
    //  defender_protection: The defender's protection
    let a: felt = sqrt(100 * defender_protection);
    let (b: felt, _) = unsigned_div_rem(defender_protection, 2);
    return (a + b,);
}

func substract_unsigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: felt, y: felt
) -> (z: felt) {
    // Subtract y to x, but the returned value is 0 if y >= x
    //
    // Parameters:
    //  x: The first value
    //  y: The second value
    //
    // Returns:
    //  z: The difference of x and y
    let test: felt = is_le(y, x);
    if (test == TRUE) {
        return (x - y,);
    }
    return (0,);
}

func perform_turns{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    a_id, a_strength, a_protection, b_id, b_strength, b_protection
) -> (winner_id: felt, loser_id: felt, a_protection: felt) {
    // Perform the turns logic until a convoy loses
    //
    // Parameters:
    //  a_id: The id of the attacker
    //  a_strength: The attacker's strength
    //  a_protection: The attacker's protection
    //  b_id: The id of the defender
    //  b_strength: The defender's strength
    //  b_protection: The defender's protection

    let test: felt = is_le(b_protection, a_strength);
    if (test == TRUE) {
        let (new_a_protection) = substract_unsigned(b_protection, a_strength);
        let (new_a_strength, _) = unsigned_div_rem(b_strength * new_a_protection, b_protection);
        return perform_turns(
            b_id, new_a_strength, new_a_protection, a_id, a_strength, a_protection
        );
    } else {
        return (b_id, a_id, b_protection);
    }
}

func copy_profits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    loser_id, winner_id
) -> () {
    // Copy the conveyables with no protection from the loser to the winner
    //
    // Parameters:
    //  loser_id: The id of the loser
    //  winner_id: The id of the winner
    Fungibles.copy(wood_balances.addr, loser_id, winner_id);
    return ();
}

func kill_soldiers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    winner_id, ratio_num, ratio_den
) -> () {
    // Kill soldier conveyables in proportion to ratio
    //
    // Parameters:
    //  winner_id: The id of the winner
    //  ratio_num: The numerator of the ratio
    //  ratio_den: The denominator of the ratio

    let (human_amount: felt) = Fungibles.amount(human_balances.addr, winner_id);
    let (divided: felt, _) = unsigned_div_rem(human_amount * ratio_num, ratio_den);
    Fungibles.set(human_balances.addr, winner_id, divided);

    let (soldier_amount) = Fungibles.amount(soldier_balances.addr, winner_id);
    let (divided: felt, _) = unsigned_div_rem(soldier_amount * ratio_num, ratio_den);
    Fungibles.set(soldier_balances.addr, winner_id, divided);

    return ();
}

func assert_is_puppet_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    colony_id, player
) -> () {
    // Check if a colony is a puppet of a player
    //
    // Parameters:
    //  colony_id: The id of the colony
    //  player: The id of the player
    //
    // Returns:
    //  bool: TRUE if the colony is a puppet of the player, FALSE otherwise
    alloc_locals;
    let (colony: Colony) = find_redirected_colony(colony_id);
    let (id) = chained_convoys.read(colony.x, colony.y);
    let (convoy_ids_len, convoy_ids) = _get_next_convoys(id, colony.x, colony.y);
    let (player_strength, others_protection) = get_puppet_scores(
        convoy_ids_len, convoy_ids, player
    );
    assert_le(others_protection, player_strength);
    return ();
}

func get_puppet_scores{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    convoy_ids_len, convoy_ids: felt*, player
) -> (player_strength: felt, others_protection: felt) {
    if (convoy_ids_len == 0) {
        return (0, 0);
    }
    alloc_locals;
    let convoy_id = [convoy_ids];
    let (player_strength, others_protection) = get_puppet_scores(
        convoy_ids_len - 1, convoy_ids + 1, player
    );
    let (test) = can_spend_convoy(convoy_id, player);
    if (test == TRUE) {
        let (strength) = get_convoy_strength(convoy_id);
        return (player_strength + strength, others_protection);
    } else {
        let (protection) = get_convoy_protection(convoy_id);
        return (player_strength, others_protection + protection);
    }
}
