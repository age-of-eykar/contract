%lang starknet

from cairo_math_64x61.vec64x61 import Vec64x61

@view
func vec64x61_add_test{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (
    res: (felt, felt, felt)
  ) {
  let res = Vec64x61.add(a, b);
  return (res,);
}

@view
func vec64x61_sub_test{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (
    res: (felt, felt, felt)
  ) {
  let res = Vec64x61.sub(a, b);
  return (res,);
}

@view
func vec64x61_mul_test{range_check_ptr}(a: (felt, felt, felt), b: felt) -> (
    res: (felt, felt, felt)
  ) {
  let res = Vec64x61.mul(a, b);
  return (res,);
}

@view
func vec64x61_dot_test{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (
    res: felt
  ) {
  let res = Vec64x61.dot(a, b);
  return (res,);
}

@view
func vec64x61_cross_test{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (
    res: (felt, felt, felt)
  ) {
  let res = Vec64x61.cross(a, b);
  return (res,);
}

@view
func vec64x61_norm_test{range_check_ptr}(a: (felt, felt, felt)) -> (res: felt) {
  let res = Vec64x61.norm(a);
  return (res,);
}
