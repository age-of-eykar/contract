%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.world import Structure

@view
func test_structure_enum{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    assert Structure.NONE = 0
    assert Structure.SETTLER_CAMP = 1
    assert Structure.LUMBER_CAMP = 2
    return ()
end
