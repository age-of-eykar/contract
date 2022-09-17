%lang starknet

from starkware.cairo.common.uint256 import Uint256

from cairo_math_64x61.math64x61 import Math64x61

@view
func math64x61_toUint256_test{range_check_ptr}(x:felt) -> (res: Uint256) {
  let res = Math64x61.toUint256(x);
  return (res,);
}

@view
func math64x61_floor_test{range_check_ptr}(x: felt) -> (res: felt) {
  return (res = Math64x61.floor(x));
}

@view
func math64x61_ceil_test{range_check_ptr}(x: felt) -> (res: felt) {
  return (res = Math64x61.ceil(x));
}

@view
func math64x61_min_test{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
  return (res = Math64x61.min(x, y));
}

@view
func math64x61_max_test{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
  return (res = Math64x61.max(x, y));
}

@view
func math64x61_mul_test{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
  return (res = Math64x61.mul(x, y));
}

@view
func math64x61_div_test{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
  return (res = Math64x61.div(x, y));
}

@view
func math64x61_pow_test{range_check_ptr}(x: felt, y: felt) -> (res: felt) {
  let res = Math64x61.pow(x, y);
  return (res,);
}

@view
func math64x61_sqrt_test{range_check_ptr}(x: felt) -> (res: felt) {
  return (res = Math64x61.sqrt(x));
}

@view
func math64x61_exp2_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Math64x61.exp2(x);
  return (res,);
}

// Calculates the natural exponent of x: e^x
@view
func math64x61_exp_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Math64x61.exp(x);
  return (res,);
}

@view
func math64x61_log2_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Math64x61.log2(x);
  return (res,);
}

@view
func math64x61_ln_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Math64x61.ln(x);
  return (res,);
}

@view
func math64x61_log10_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Math64x61.log10(x);
  return (res,);
}
