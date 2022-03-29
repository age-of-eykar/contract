%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from contracts.fixed_point_numbers import (
    Math64x61_assert64x61 as assert64x61,
    Math64x61_toFelt as to_felt,
    Math64x61_fromFelt as from_felt,
    Math64x61_add as add,
    Math64x61_sub as sub,
    Math64x61_mul as mul,
    Math64x61_div as div,
    Math64x61_pow as pow,
    Math64x61_sqrt as sqrt,
    Math64x61_ONE as ONE,
)

@view
func sixth{range_check_ptr}()->(sixth: felt):
    alloc_locals
    let (six) = from_felt(6)
    let (sixth) = div(ONE, six)
    return (sixth)
end

@view
func sqrt_three{range_check_ptr}()->(sqrt_three: felt):
    alloc_locals
    let (three) = from_felt(3)
    let (sqrt_three) = sqrt(three)
    return (sqrt_three)
end

@view
func test_sqrt_three{range_check_ptr}()->(res: felt):
    alloc_locals
    let (three) = from_felt(3)
    let (sqrt_three) = sqrt(three)
    let (res) = pow(sqrt_three, 2)
    let (res) = to_felt(res)
    return (res)
end

@view
func half{range_check_ptr}()->(half: felt):
    alloc_locals
    let (two) = from_felt(2)
    let (half) = div(ONE, two)
    return (half)
end

@view
func test_half{range_check_ptr}()->(test_half: felt):
    alloc_locals
    let (two) = from_felt(2)
    let (half) = div(ONE, two)
    let (test_half) = mul(half, two)
    let (test_half) = to_felt(test_half)
    return (test_half)
end

@view
func three{range_check_ptr}()->(three: felt):
    alloc_locals
    let (three) = from_felt(3)
    return (three)
end

@view
func test_three{range_check_ptr}()->(res: felt):
    alloc_locals
    let (three) = from_felt(3)
    let (res) = to_felt(three)
    return (res)
end

@view
func two{range_check_ptr}()->(two: felt):
    alloc_locals
    let (two) = from_felt(2)
    return (two)
end

@view
func test_two{range_check_ptr}()->(res: felt):
    alloc_locals
    let (two) = from_felt(2)
    let (res) = to_felt(two)
    return (res)
end

@view
func seventy{range_check_ptr}()->(seventy: felt):
    alloc_locals
    let (seventy) = from_felt(70)
    return (seventy)
end

@view
func test_seventy{range_check_ptr}()->(res: felt):
    alloc_locals
    let (seventy) = from_felt(70)
    let (res) = to_felt(seventy)
    return (res)
end

@view 
func minus_two{range_check_ptr}()->(res: felt):
    alloc_locals
    let (minus_two) = from_felt(-2)
    return (minus_two)
end


@view 
func test_minus_two{range_check_ptr}()->(res: felt):
    alloc_locals
    let (minus_two) = from_felt(-2)
    let (minus_one) = from_felt(-1)
    let (two) = mul(minus_two, minus_one)
    let (res) = to_felt(two)
    return (res)
end