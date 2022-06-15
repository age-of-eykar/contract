%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le
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

    return ()
end

func defender_protection_modifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(defender_protection : felt) -> (modified_protection : felt):
    let (a : felt) = sqrt(100 * defender_protection)
    let (b : felt, _) = unsigned_div_rem(defender_protection, 2)
    return (a + b)
end
