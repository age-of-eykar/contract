%lang starknet

from cairo_math_64x61.hyp64x61 import Hyp64x61

@view
func hyp64x61_sinh_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Hyp64x61.sinh(x);
  return (res,);
}

@view
func hyp64x61_cosh_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Hyp64x61.cosh(x);
  return (res,);
}

@view
func hyp64x61_tanh_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Hyp64x61.tanh(x);
  return (res,);
}

@view
func hyp64x61_asinh_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Hyp64x61.asinh(x);
  return (res,);
}

@view
func hyp64x61_acosh_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Hyp64x61.acosh(x);
  return (res,);
}

@view
func hyp64x61_atanh_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Hyp64x61.atanh(x);
  return (res,);
}
