%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.math import unsigned_div_rem

func compute_szudzik{range_check_ptr}(a: felt) -> (res: felt):
    let (temp) = is_nn(a)
    if temp != 0:
        return (a * 2)
    else:
        return (a * -2 - 1)
    end
end

func szudzik{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    alloc_locals

    let (xx) = compute_szudzik(x)
    let (yy) = compute_szudzik(y)
    
    let (temp_res) = is_le(yy, xx)
    if temp_res != 0:
        tempvar res = xx * xx + xx + yy
    else:
        tempvar res = yy * yy + xx
    end
    return (res)
end

func lcg{range_check_ptr}(seed: felt, loop: felt) -> (seed: felt):
    if loop == 0:
        return (seed)
    else:
        let temp1 = seed * 1103515245 + 12345
        let (_, temp2) = unsigned_div_rem(temp1, 999999937)
        return lcg(seed=temp2, loop=loop-1)
    end
end