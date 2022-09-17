from cairo_math_64x61.math64x61 import Math64x61

namespace Hyp64x61 {
	// Calculates hyperbolic sine of x (fixed point)
	func sinh{range_check_ptr}(x: felt) -> felt {
		alloc_locals;

		let ex = Math64x61.exp(x);
		let ex_i = Math64x61.div(Math64x61.ONE, ex);
		let res = Math64x61.div(ex - ex_i, 2 * Math64x61.ONE);
		Math64x61.assert64x61(res);
		return res;
	}

	// Calculates hyperbolic cosine of x (fixed point)
	func cosh{range_check_ptr}(x: felt) -> felt {
		alloc_locals;

		let ex = Math64x61.exp(x);
		let ex_i = Math64x61.div(Math64x61.ONE, ex);
		let res = Math64x61.div(ex + ex_i, 2 * Math64x61.ONE);
		Math64x61.assert64x61(res);
		return res;
	}

	// Calculates hyperbolic tangent of x (fixed point)
	func tanh{range_check_ptr}(x: felt) -> felt {
		alloc_locals;

		let ex = Math64x61.exp(x);
		let ex_i = Math64x61.div(Math64x61.ONE, ex);
		let res = Math64x61.div(ex - ex_i, ex + ex_i);
		Math64x61.assert64x61(res);
		return res;
	}

	// Calculates inverse hyperbolic sine of x (fixed point)
	func asinh{range_check_ptr}(x: felt) -> felt {
		let x2 = Math64x61.mul(x, x);
		let root = Math64x61.sqrt(x2 + Math64x61.ONE);
		let res = Math64x61.ln(x + root);
		Math64x61.assert64x61(res);
		return res;
	}

	// Calculates inverse hyperbolic cosine of x (fixed point)
	func acosh{range_check_ptr}(x: felt) -> felt {
		let x2 = Math64x61.mul(x, x);
		let root = Math64x61.sqrt(x2 - Math64x61.ONE);
		let res = Math64x61.ln(x + root);
		Math64x61.assert64x61(res);
		return res;
	}

	// Calculates inverse hyperbolic tangent of x (fixed point)
	func atanh{range_check_ptr}(x: felt) -> felt {
		let _ln_arg = Math64x61.div(Math64x61.ONE + x, Math64x61.ONE - x);
		let _ln = Math64x61.ln(_ln_arg);
		let res = Math64x61.div(_ln, 2 * Math64x61.ONE);
		Math64x61.assert64x61(res);
		return res;
	}
}
