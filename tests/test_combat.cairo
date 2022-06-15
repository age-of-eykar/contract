%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.combat import defender_protection_modifier

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
