%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.colonies import Colony, create_colony, find_redirected_colony, redirect_colony

@view
func test_create_colony{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (local colony1 : Colony) = create_colony('hola', 123, 1, -4)
    let (colony : Colony) = find_redirected_colony(colony1.redirection)
    assert colony.name = 'hola'
    assert colony.owner = 123
    assert colony.x = 1
    assert colony.y = -4
    assert colony.redirection = colony1.redirection
    return ()
end

@view
func test_redirect_colony{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (colony1 : Colony) = create_colony('hola', 123, 1, -4)
    let (colony2 : Colony) = create_colony('allo', 123, 1, -4)
    assert colony1.redirection = 1
    assert colony2.redirection = 2

    redirect_colony(2, 1)
    let (colony1 : Colony) = find_redirected_colony(1)
    let (colony2 : Colony) = find_redirected_colony(2)

    assert colony1.redirection = 1
    assert colony2.redirection = 1
    return ()
end
