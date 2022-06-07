%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import (
    assert_le,
    sign,
    abs_value,
    signed_div_rem,
    unsigned_div_rem
)

const Math64x61_INT_PART = 2 ** 64
const Math64x61_FRACT_PART = 2 ** 61
const Math64x61_BOUND = 2 ** 125
const Math64x61_ONE = 1 * Math64x61_FRACT_PART

func Math64x61_assert64x61 {range_check_ptr} (x: felt):
    assert_le(x, Math64x61_BOUND)
    assert_le(-Math64x61_BOUND, x)
    return ()
end

# Converts a fixed point value to a felt, truncating the fractional component
func Math64x61_toFelt {range_check_ptr} (x: felt) -> (res: felt):
    let (res, _) = signed_div_rem(x, Math64x61_FRACT_PART, Math64x61_BOUND)
    return (res)
end

# Converts a felt to a fixed point value ensuring it will not overflow
func Math64x61_fromFelt {range_check_ptr} (x: felt) -> (res: felt):
    assert_le(x, Math64x61_INT_PART)
    assert_le(-Math64x61_INT_PART, x)
    return (x * Math64x61_FRACT_PART)
end

# Convenience addition method to assert no overflow before returning
func Math64x61_add {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let res = x + y
    Math64x61_assert64x61(res)
    return (res)
end

# Convenience subtraction method to assert no overflow before returning
func Math64x61_sub {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let res = x - y
    Math64x61_assert64x61(res)
    return (res)
end

# Multiples two fixed point values and checks for overflow before returning
func Math64x61_mul {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    tempvar product = x * y
    let (res, _) = signed_div_rem(product, Math64x61_FRACT_PART, Math64x61_BOUND)
    Math64x61_assert64x61(res)
    return (res)
end

# Divides two fixed point values and checks for overflow before returning
# Both values may be signed (i.e. also allows for division by negative b)
func Math64x61_div {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    alloc_locals
    let (div) = abs_value(y)
    let (div_sign) = sign(y)
    tempvar product = x * Math64x61_FRACT_PART
    let (res_u, _) = signed_div_rem(product, div, Math64x61_BOUND)
    Math64x61_assert64x61(res_u)
    return (res = res_u * div_sign)
end

# Calculates the floor of a 64.61 value
func Math64x61_floor {range_check_ptr} (x: felt) -> (res: felt):
    let (int_val, mod_val) = signed_div_rem(x, Math64x61_ONE, Math64x61_BOUND)
    let res = x - mod_val
    Math64x61_assert64x61(res)
    return (res)
end

# Calclates the value of x^y and checks for overflow before returning
# x is a 64x61 fixed point value
# y is a standard felt (int)
func Math64x61__pow_int {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    alloc_locals
    let (exp_sign) = sign(y)
    let (exp_val) = abs_value(y)

    if exp_sign == 0:
        return (Math64x61_ONE)
    end

    if exp_sign == -1:
        let (num) = Math64x61__pow_int(x, exp_val)
        return Math64x61_div(Math64x61_ONE, num)
    end

    let (half_exp, rem) = unsigned_div_rem(exp_val, 2)
    let (half_pow) = Math64x61__pow_int(x, half_exp)
    let (res_p) = Math64x61_mul(half_pow, half_pow)

    if rem == 0:
        Math64x61_assert64x61(res_p)
        return (res_p)
    else:
        let (res) = Math64x61_mul(res_p, x)
        Math64x61_assert64x61(res)
        return (res)
    end
end

# Calculates the binary exponent of x: 2^x
func Math64x61_exp2 {range_check_ptr} (x: felt) -> (res: felt):
    alloc_locals

    let (exp_sign) = sign(x)

    if exp_sign == 0:
        return (Math64x61_ONE)
    end

    let (exp_value) = abs_value(x)
    let (int_part, frac_part) = unsigned_div_rem(exp_value, Math64x61_FRACT_PART)
    let (int_res) = Math64x61__pow_int(2 * Math64x61_ONE, int_part)

    # 1.069e-7 maximum error
    const a1 = 2305842762765193127
    const a2 = 1598306039479152907
    const a3 = 553724477747739017
    const a4 = 128818789015678071
    const a5 = 20620759886412153
    const a6 = 4372943086487302

    let (r6) = Math64x61_mul(a6, frac_part)
    let (r5) = Math64x61_mul(r6 + a5, frac_part)
    let (r4) = Math64x61_mul(r5 + a4, frac_part)
    let (r3) = Math64x61_mul(r4 + a3, frac_part)
    let (r2) = Math64x61_mul(r3 + a2, frac_part)
    tempvar frac_res = r2 + a1

    let (res_u) = Math64x61_mul(int_res, frac_res)
    
    if exp_sign == -1:
        let (res_i) = Math64x61_div(Math64x61_ONE, res_u)
        Math64x61_assert64x61(res_i)
        return (res_i)
    else:
        Math64x61_assert64x61(res_u)
        return (res_u)
    end
end