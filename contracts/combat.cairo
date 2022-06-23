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
    contains_convoy,
    get_convoys,
    burn_convoy,
    convoy_meta,
    ConvoyMeta,
)
from contracts.colonies import Colony, get_colony

@external
func attack{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    attacker : felt, target : felt, x : felt, y : felt
) -> ():
    # Attack target convoy with attacker convoy (which needs to belong to the caller)
    # targets needs to be part of attacker plot
    #
    # Parameters:
    #  attacker: The attacker's convoy
    #  target: The target's convoy
    #  x: The x coordinate of the target's convoy
    #  y: The y coordinate of the target's convoy

    alloc_locals
    let (caller) = get_caller_address()

    # assert attacker can be spent
    assert_can_spend_convoy(attacker, caller)

    # check attacker is on this plot
    let (test) = contains_convoy(attacker, x, y)
    assert test = TRUE

    # assert target has arrived
    let (timestamp) = get_block_timestamp()
    let (meta_target : ConvoyMeta) = convoy_meta.read(target)
    assert_le(meta_target.availability, timestamp)

    # check target is on this plot
    let (test) = contains_convoy(target, x, y)
    assert test = TRUE

    # find original stength and protection
    let (attacker_strength) = get_convoy_strength(attacker)
    let (attacker_protection) = get_convoy_protection(attacker)
    let (target_strength) = get_convoy_strength(target)
    let (target_protection) = get_convoy_protection(target)

    let (modified_target_protection) = defender_protection_modifier(target_protection)

    let (winner_id, loser_id, winner_protection) = perform_turns(
        attacker,
        attacker_strength,
        attacker_protection,
        target,
        target_strength,
        modified_target_protection,
    )

    local original_protection : felt
    if winner_id == attacker:
        assert original_protection = attacker_protection
    else:
        assert original_protection = modified_target_protection
    end
    copy_profits(loser_id, winner_id)
    kill_soldiers(winner_id, winner_protection, original_protection)
    burn_convoy(loser_id)

    return ()
end

func defender_protection_modifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(defender_protection : felt) -> (modified_protection : felt):
    # Modify the defender's protection to give a bonus to small defenders and a malus to big defenders
    #
    # Parameters:
    #  defender_protection: The defender's protection
    let (a : felt) = sqrt(100 * defender_protection)
    let (b : felt, _) = unsigned_div_rem(defender_protection, 2)
    return (a + b)
end

func substract_unsigned{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt
) -> (z : felt):
    # Subtract y to x, but the returned value is 0 if y >= x
    #
    # Parameters:
    #  x: The first value
    #  y: The second value
    #
    # Returns:
    #  z: The difference of x and y
    let (test : felt) = is_le(y, x)
    if test == TRUE:
        return (x - y)
    end
    return (0)
end

func perform_turns{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a_id, a_strength, a_protection, b_id, b_strength, b_protection
) -> (winner_id, loser_id, a_protection):
    # Perform the turns logic until a convoy loses
    #
    # Parameters:
    #  a_id: The id of the attacker
    #  a_strength: The attacker's strength
    #  a_protection: The attacker's protection
    #  b_id: The id of the defender
    #  b_strength: The defender's strength
    #  b_protection: The defender's protection

    let (test : felt) = is_le(b_protection, a_strength)
    if test == TRUE:
        let (new_a_protection) = substract_unsigned(b_protection, a_strength)
        let (new_a_strength, _) = unsigned_div_rem(b_strength * new_a_protection, b_protection)
        return perform_turns(b_id, new_a_strength, new_a_protection, a_id, a_strength, a_protection)
    else:
        return (b_id, a_id, b_protection)
    end
end

func copy_profits{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    loser_id, winner_id
) -> ():
    # Copy the conveyables with no protection from the loser to the winner
    #
    # Parameters:
    #  loser_id: The id of the loser
    #  winner_id: The id of the winner
    Fungibles.copy(wood_balances.addr, loser_id, winner_id)
    return ()
end

func kill_soldiers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    winner_id, ratio_num, ratio_den
) -> ():
    # Kill soldier conveyables in proportion to ratio
    #
    # Parameters:
    #  winner_id: The id of the winner
    #  ratio_num: The numerator of the ratio
    #  ratio_den: The denominator of the ratio

    let (human_amount : felt) = Fungibles.amount(human_balances.addr, winner_id)
    let (divided : felt, _) = unsigned_div_rem(human_amount * ratio_num, ratio_den)
    Fungibles.set(human_balances.addr, winner_id, divided)

    let (soldier_amount) = Fungibles.amount(soldier_balances.addr, winner_id)
    let (divided : felt, _) = unsigned_div_rem(soldier_amount * ratio_num, ratio_den)
    Fungibles.set(soldier_balances.addr, winner_id, divided)

    return ()
end

func is_puppet_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    colony_id, player
) -> (bool : felt):
    # Check if a colony is a puppet of a player
    #
    # Parameters:
    #  colony_id: The id of the colony
    #  player: The id of the player
    #
    # Returns:
    #  bool: TRUE if the colony is a puppet of the player, FALSE otherwise
    alloc_locals
    let (colony : Colony) = get_colony(colony_id)
    let (convoy_ids_len, convoy_ids) = get_convoys(colony.x, colony.y)
    let (player_strength, others_protection) = get_puppet_scores(convoy_ids_len, convoy_ids, player)
    let (test) = is_le(others_protection, player_strength)
    return (test)
end

func get_puppet_scores{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_ids_len, convoy_ids : felt*, player
) -> (player_strength, others_protection):
    if convoy_ids_len == 0:
        return (0, 0)
    end
    alloc_locals
    let convoy_id = [convoy_ids]
    let (player_strength, others_protection) = get_puppet_scores(
        convoy_ids_len - 1, convoy_ids + 1, player
    )
    let (test) = can_spend_convoy(convoy_id, player)
    if test == TRUE:
        let (strength) = get_convoy_strength(convoy_id)
        return (player_strength + strength, others_protection)
    else:
        let (protection) = get_convoy_protection(convoy_id)
        return (player_strength, others_protection + protection)
    end
end
