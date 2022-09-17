from cairo_math_64x61.math64x61 import Math64x61

namespace Vec64x61 {
  // Calculate the vector sum of two 3D vectors
  func add{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (felt, felt, felt) {
    let x = Math64x61.add(a[0], b[0]);
    let y = Math64x61.add(a[1], b[1]);
    let z = Math64x61.add(a[2], b[2]);
    return (x, y, z);
  }

  // Calculates vector subtraction for two 3D vectors
  func sub{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (felt, felt, felt) {
    let x = Math64x61.sub(a[0], b[0]);
    let y = Math64x61.sub(a[1], b[1]);
    let z = Math64x61.sub(a[2], b[2]);
    return (x, y, z);
  }

  // Calculates the scalar product of a 3D vector and a fixed point value
  func mul{range_check_ptr}(a: (felt, felt, felt), b: felt) -> (felt, felt, felt) {
    let x = Math64x61.mul(a[0], b);
    let y = Math64x61.mul(a[1], b);
    let z = Math64x61.mul(a[2], b);
    return (x, y, z);
  }

  // Calculates the dot product of two 3D vectors
  func dot{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> felt {
    let x = Math64x61.mul(a[0], b[0]);
    let y = Math64x61.mul(a[1], b[1]);
    let z = Math64x61.mul(a[2], b[2]);
    return Math64x61.add(x + y, z);
  }

  // Calculates the cross product of two 3D vectors
  func cross{range_check_ptr}(a: (felt, felt, felt), b: (felt, felt, felt)) -> (felt, felt, felt) {
    let x1 = Math64x61.mul(a[1], b[2]);
    let x2 = Math64x61.mul(a[2], b[1]);
    let x = Math64x61.sub(x1, x2);
    let y1 = Math64x61.mul(a[2], b[0]);
    let y2 = Math64x61.mul(a[0], b[2]);
    let y = Math64x61.sub(y1, y2);
    let z1 = Math64x61.mul(a[0], b[1]);
    let z2 = Math64x61.mul(a[1], b[0]);
    let z = Math64x61.sub(z1, z2);
    return (x, y, z);
  }

  // Calculates the length / norm (L2) of a 3D vector
  func norm{range_check_ptr}(a: (felt, felt, felt)) -> felt {
    let x2 = Math64x61.mul(a[0], a[0]);
    let y2 = Math64x61.mul(a[1], a[1]);
    let z2 = Math64x61.mul(a[2], a[2]);
    return Math64x61.sqrt(x2 + y2 + z2);
  }
}
