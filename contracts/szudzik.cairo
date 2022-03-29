%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.math import unsigned_div_rem, assert_250_bit

func szudzik{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    alloc_locals

    let (temp_x) = is_nn(x)
    if temp_x == 1:
        tempvar temp = x * 2
    else:
        tempvar temp = x * -2 - 1
    end
    local xx = temp

    let (temp_y) = is_nn(y)
    if temp_y == 1:
        tempvar temp = x * 2
    else:
        tempvar temp = x * -2 - 1
    end
    local yy = temp
    
    let (temp) = is_le(yy, xx)
    if temp == 1:
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
        tempvar temp1 = seed * 7919 + 12345
        assert_250_bit(temp1)
        let (_, temp2) = unsigned_div_rem(temp1, 5857)
        return lgc(seed=temp2, loop=loop-1)
    end
end

@view
func random_felt{range_check_ptr}(x: felt, y: felt, loop: felt, s: felt, modulo: felt) -> (res: felt):
    let (temp) = szudzik(x, y)
    let (random) = lgc(temp + s, loop)
    let (_, res) = unsigned_div_rem(random, modulo)
    return (res)
end