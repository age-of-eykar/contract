from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import sign, abs_value, unsigned_div_rem, assert_not_zero
from cairo_math_64x61.math64x61 import Math64x61

namespace Trig64x61 {
  const PI = 7244019458077122842;
  const HALF_PI = 3622009729038561421;

  // Calculates sin(x) with x in radians (fixed point)
  func sin{range_check_ptr}(x: felt) -> felt   {
    alloc_locals;

    let _sign1 = sign(x);  // extract sign
    let abs1 = abs_value(x);
    let (_, x1) = unsigned_div_rem(abs1, 2 * PI);
    let (rem, x2) = unsigned_div_rem(x1, PI);
    local _sign2 = 1 - (2 * rem);
    let acc = _sin_loop(x2, 6, Math64x61.ONE);
    let res2 = Math64x61.mul(x2, acc);
    local res = res2 * _sign1 * _sign2;
    Math64x61.assert64x61(res);
    return res;
  }

  // Calculates cos(x) with x in radians (fixed point)
  func cos{range_check_ptr}(x: felt) -> felt   {
    tempvar shifted = HALF_PI - x;
    let res = sin(shifted);
    return res;
  }

  // Calculates tan(x) with x in radians (fixed point)
  func tan{range_check_ptr}(x: felt) -> felt   {
    alloc_locals;

    let sinx = sin(x);
    let cosx = cos(x);
    assert_not_zero(cosx);
    let res = Math64x61.div(sinx, cosx);
    return res;
  }

  // Calculates arctan(x) (fixed point)
  // See https://stackoverflow.com/a/50894477 for range adjustments
  func atan{range_check_ptr}(x: felt) -> felt   {
    alloc_locals;

    const sqrt3_3 = 1331279082078542925;  // sqrt(3) / 3
    const pi_6 = 1207336576346187140;  // pi / 6
    const p_7 = 1614090106449585766;  // 0.7

    // Calculate on positive values and re-assign later
    let _sign = sign(x);
    let abs_x = abs_value(x);

    // Invert value when x > 1
    let _invert = is_le(Math64x61.ONE, abs_x);
    local x1a_num = abs_x * (1 - _invert) + _invert * Math64x61.ONE;
    tempvar x1a_div = abs_x * _invert + Math64x61.ONE - Math64x61.ONE * _invert;
    let x1a = Math64x61.div(x1a_num, x1a_div);

    // Account for lack of precision in polynomaial when x > 0.7
    let _shift = is_le(p_7, x1a);
    local b = sqrt3_3 * _shift + Math64x61.ONE - _shift * Math64x61.ONE;
    local x1b_num = x1a - b;
    tempvar x1b_div = Math64x61.ONE + Math64x61.mul(x1a, b);
    let x1b = Math64x61.div(x1b_num, x1b_div);
    local x1 = x1a * (1 - _shift) + x1b * _shift;

    // 6.769e-8 maximum error
    const a1 = -156068910203;
    const a2 = 2305874223272159097;
    const a3 = -1025642721113314;
    const a4 = -755722092556455027;
    const a5 = -80090004380535356;
    const a6 = 732863004158132014;
    const a7 = -506263448524254433;
    const a8 = 114871904819177193;

    let r8 = Math64x61.mul(a8, x1);
    let r7 = Math64x61.mul(r8 + a7, x1);
    let r6 = Math64x61.mul(r7 + a6, x1);
    let r5 = Math64x61.mul(r6 + a5, x1);
    let r4 = Math64x61.mul(r5 + a4, x1);
    let r3 = Math64x61.mul(r4 + a3, x1);
    let r2 = Math64x61.mul(r3 + a2, x1);
    tempvar z1 = r2 + a1;

    // Adjust for sign change, inversion, and shift
    tempvar z2 = z1 + (pi_6 * _shift);
    tempvar z3 = (z2 - (HALF_PI * _invert)) * (1 - _invert * 2);
    local res = z3 * _sign;
    Math64x61.assert64x61(res);
    return res;
  }

  // Calculates arcsin(x) for -1 <= x <= 1 (fixed point)
  // arcsin(x) = arctan(x / sqrt(1 - x^2))
  func asin{range_check_ptr}(x: felt) -> felt   {
    alloc_locals;

    let _sign = sign(x);
    let x1 = abs_value(x);

    if (x1 == Math64x61.ONE) {
      return HALF_PI * _sign;
    }

    let x1_2 = Math64x61.mul(x1, x1);
    let div = Math64x61.sqrt(Math64x61.ONE - x1_2);
    let atan_arg = Math64x61.div(x1, div);
    let res_u = atan(atan_arg);
    return res_u * _sign;
  }

  // Calculates arccos(x) for -1 <= x <= 1 (fixed point)
  // arccos(x) = arcsin(sqrt(1 - x^2)) - arctan identity has discontinuity at zero
  func acos{range_check_ptr}(x: felt) -> felt   {
    alloc_locals;

    let _sign = sign(x);
    let x1 = abs_value(x);
    let x1_2 = Math64x61.mul(x1, x1);
    let asin_arg = Math64x61.sqrt(Math64x61.ONE - x1_2);
    let res_u = asin(asin_arg);

    if (_sign == -1) {
      local res = PI - res_u;
      Math64x61.assert64x61(res);
      return res;
    } else {
      return res_u;
    }
  }

  // Helper function to calculate Taylor series for sin
  func _sin_loop{range_check_ptr}(x: felt, i: felt, acc: felt) -> felt   {
    alloc_locals;

    if (i == -1) {
      return acc;
    }

    let num = Math64x61.mul(x, x);
    tempvar div = (2 * i + 2) * (2 * i + 3) * Math64x61.FRACT_PART;
    let t = Math64x61.div(num, div);
    let t_acc = Math64x61.mul(t, acc);
    let next = _sin_loop(x, i - 1, Math64x61.ONE - t_acc);
    return next;
  }
}
