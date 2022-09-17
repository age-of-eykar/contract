from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

func max{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(a: felt, b: felt) -> (
    max: felt
) {
    let test = is_le(a, b);
    if (test == TRUE) {
        return (b,);
    } else {
        return (a,);
    }
}
