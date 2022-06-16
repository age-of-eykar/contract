%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from contracts.convoys.library import (
    get_convoy_strength,
    get_convoy_protection,
    assert_can_spend_convoy,
    contains_convoy,
    convoy_meta,
    ConvoyMeta,
)

@external
func attack{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    attacker : felt, target : felt, x : felt, y : felt
) -> ():
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

    let (protection_max) = new_max_protection(
        winner_id,
        attacker,
        winner_protection,
        attacker_protection,
        target_protection,
        modified_target_protection,
    )

    copy_profits(loser_id, winner_id)
    kill_soldiers(winner_id, protection_max)
    burn_convoy(loser_id)

    return ()
end

func defender_protection_modifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(defender_protection : felt) -> (modified_protection : felt):
    let (a : felt) = sqrt(100 * defender_protection)
    let (b : felt, _) = unsigned_div_rem(defender_protection, 2)
    return (a + b)
end

func new_max_protection{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    winner_id,
    attacker_id,
    winner_protection,
    attacker_protection,
    target_protection,
    modified_target_protection,
) -> (boundary : felt):
    if winner_id == attacker_id:
        return (winner_protection)
    else:
        let (boundary : felt, _) = unsigned_div_rem(
            target_protection * winner_protection, modified_target_protection
        )
        return (boundary)
    end
end

func perform_turns{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a_id, a_strength, a_protection, b_id, b_strength, b_protection
) -> (winner_id, loser_id, a_protection):
    let (test : felt) = is_le(b_protection, a_strength)
    if test == TRUE:
        let new_a_protection = b_protection - a_strength
        let (new_a_strength, _) = unsigned_div_rem(b_strength * new_a_protection, b_protection)
        return perform_turns(b_id, new_a_strength, new_a_protection, a_id, a_strength, a_protection)
    else:
        return (a_id, b_id, a_protection)
    end
end

func copy_profits{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    loser_id, winner_id
) -> ():
    # todo
    ret
end

func kill_soldiers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    loser_id, winner_id
) -> ():
    # todo
    ret
end

func burn_convoy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(convoy_id) -> (
    ):
    # todo
    ret
end
