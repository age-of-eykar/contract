%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

func sum{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    felt_list_len: felt, felt_list: felt*
) -> (sum: felt) {
    if (felt_list_len == 0) {
        return (0,);
    }
    let (rest) = sum(felt_list_len - 1, felt_list);
    return (rest + felt_list[felt_list_len - 1],);
}
