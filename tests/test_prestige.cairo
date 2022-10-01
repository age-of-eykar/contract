%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from contracts.prestige import add_prestige
from contracts.eykar import get_prestige

@view
func test_add_prestige{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (prestige) = get_prestige('thomas');
    assert prestige = 0;

    add_prestige('thomas', 5);
    let (prestige) = get_prestige('thomas');
    assert prestige = 5;

    add_prestige('thomas', 5);
    let (prestige) = get_prestige('thomas');
    assert prestige = 10;

    let (prestige) = get_prestige('louis');
    assert prestige = 0;

    return ();
}
