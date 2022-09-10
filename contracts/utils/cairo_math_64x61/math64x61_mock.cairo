%lang starknet

from cairo_math_64x61.math64x61 import Math64x61

@view
func math64x61_floor_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.floor(x)
    return (res)
end

@view
func math64x61_ceil_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.ceil(x)
    return (res)
end

@view
func math64x61_min_test {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let (res) = Math64x61.min(x, y)
    return (res)
end

@view
func math64x61_max_test {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let (res) = Math64x61.max(x, y)
    return (res)
end

@view
func math64x61_mul_test {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let (res) = Math64x61.mul(x, y)
    return (res)
end

@view
func math64x61_div_test {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let (res) = Math64x61.div(x, y)
    return (res)
end

@view
func math64x61_pow_test {range_check_ptr} (x: felt, y: felt) -> (res: felt):
    let (res) = Math64x61.pow(x, y)
    return (res)
end

@view
func math64x61_sqrt_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.sqrt(x)
    return (res)
end

@view
func math64x61_exp2_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.exp2(x)
    return (res)
end

# Calculates the natural exponent of x: e^x
@view
func math64x61_exp_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.exp(x)
    return (res)
end

@view
func math64x61_log2_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.log2(x)
    return (res)
end

@view
func math64x61_ln_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.ln(x)
    return (res)
end

@view
func math64x61_log10_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Math64x61.log10(x)
    return (res)
end
