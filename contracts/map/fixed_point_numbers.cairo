%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import (
    assert_le,
    assert_lt,
    sqrt,
    sign,
    abs_value,
    signed_div_rem,
)

const Math64x61_INT_PART = 2 ** 64
const Math64x61_FRACT_PART = 2 ** 61
const Math64x61_BOUND = 2 ** 125
const Math64x61_ONE = 1 * Math64x61_FRACT_PART
const Math64x61_E = 6267931151224907085

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

# Calculates the square root of a fixed point value
# x must be positive
func Math64x61_sqrt {range_check_ptr} (x: felt) -> (res: felt):
    alloc_locals
    let (root) = sqrt(x)
    let (scale_root) = sqrt(Math64x61_FRACT_PART)
    let (res, _) = signed_div_rem(root * Math64x61_FRACT_PART, scale_root, Math64x61_BOUND)
    Math64x61_assert64x61(res)
    return (res)
end

# Calculates the floor of a 64.61 value
func Math64x61_floor {range_check_ptr} (x: felt) -> (res: felt):
    let (int_val, mod_val) = signed_div_rem(x, Math64x61_ONE, Math64x61_BOUND)
    let res = x - mod_val
    Math64x61_assert64x61(res)
    return (res)
end