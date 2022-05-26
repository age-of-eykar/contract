%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.math import unsigned_div_rem, assert_in_range

func szudzik{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    alloc_locals

    let (temp_x) = is_nn(x)
    if temp_x == 1:
        tempvar temp = x * 2
    else:
        tempvar temp = x * -2 - 1
    end
    let xx = temp

    let (temp_y) = is_nn(y)
    if temp_y == 1:
        tempvar temp = y * 2
    else:
        tempvar temp = y * -2 - 1
    end
    let yy = temp
    
    let (temp_res) = is_le(yy, xx)
    if temp_res == 1:
        tempvar res = xx * xx + xx + yy
    else:
        tempvar res = yy * yy + xx
    end
    return (res)
end

func lgc{range_check_ptr}(seed: felt, loop: felt) -> (seed: felt):
    if loop == 0:
        return (seed)
    else:
        let temp1 = seed * 1103515245 + 12345
        let (_, temp2) = unsigned_div_rem(temp1, 999999937)
        return lgc(seed=temp2, loop=loop-1)
    end
end