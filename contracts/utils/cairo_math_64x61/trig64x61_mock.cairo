%lang starknet

from cairo_math_64x61.trig64x61 import Trig64x61

@view
func trig64x61_sin_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Trig64x61.sin(x);
  return (res,);
}

@view
func trig64x61_cos_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Trig64x61.cos(x);
  return (res,);
}

@view
func trig64x61_tan_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Trig64x61.tan(x);
  return (res,);
}

@view
func trig64x61_atan_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Trig64x61.atan(x);
  return (res,);
}

@view
func trig64x61_asin_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Trig64x61.asin(x);
  return (res,);
}

@view
func trig64x61_acos_test{range_check_ptr}(x: felt) -> (res: felt) {
  let res = Trig64x61.acos(x);
  return (res,);
}
