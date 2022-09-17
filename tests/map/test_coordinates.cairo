%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.eykar import get_distance, spiral

@view
func test_distance{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (result) = get_distance(0, 0, 10, 10);
    assert result = 14;

    let (result) = get_distance(-5, -5, 5, 5);
    assert result = 14;

    return ();
}

@view
func test_spiral{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (x, y) = spiral(0, 0);
    assert x = 0;
    assert y = 0;

    let (x, y) = spiral(1, 0);
    assert x = 0;
    assert y = 1;

    let (x, y) = spiral(2, 0);
    assert x = 1;
    assert y = 1;

    let (x, y) = spiral(3, 0);
    assert x = 1;
    assert y = 0;

    let (x, y) = spiral(4, 0);
    assert x = 1;
    assert y = -1;

    let (x, y) = spiral(5, 0);
    assert x = 0;
    assert y = -1;

    let (x, y) = spiral(6, 0);
    assert x = -1;
    assert y = -1;

    let (x, y) = spiral(8, 0);
    assert x = -1;
    assert y = 1;

    let (x, y) = spiral(8, 1);
    assert x = -2;
    assert y = 2;

    let (x, y) = spiral(8, 10);
    assert x = -11;
    assert y = 11;

    let (x, y) = spiral(9, 0);
    assert x = -1;
    assert y = 2;

    return ();
}
