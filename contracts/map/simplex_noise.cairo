%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.math import unsigned_div_rem

from contracts.map.szudzik import lcg, szudzik
from contracts.utils.cairo_math_64x61.math64x61 import Math64x61

# 1/2 in 64.61 fixed-point format
const HALF = 1152921504606846976

# 70 in 64.61 fixed-point format
const SEVENTY = 161409010644958576640

# (sqrt(3)-1)/2 in 64.61 fixed-point format
const F = 843997118510967411

# (3-sqrt(3))/6 in 64.61 fixed-point format
const G = 487281963567575513

# G * 2 in 64.61 fixed-point format
const G2 = 974563927135151026

# 2 in 64.61 fixed-point format
const TWO = 4611686018427387904

# to switch x in 64.61 fixed format do: x *= 2 ** 61

func select_grad2{range_check_ptr}(r: felt) -> (grad2: (felt, felt)):
    let (gradient_address) = get_label_location(gradients)
    return ( ([gradient_address + r*2], [gradient_address + r*2+1]) )

    gradients:
    dw Math64x61.ONE
    dw Math64x61.ONE

    dw -Math64x61.ONE
    dw Math64x61.ONE

    dw Math64x61.ONE
    dw -Math64x61.ONE

    dw -Math64x61.ONE
    dw -Math64x61.ONE

    dw Math64x61.ONE
    dw 0

    dw -Math64x61.ONE
    dw 0

    dw 0
    dw Math64x61.ONE

    dw 0
    dw -Math64x61.ONE
end

func dot{range_check_ptr}(grad: (felt, felt), x: felt, y: felt)->(res: felt):
    let (val_x) = Math64x61.mul(grad[0], x)
    let (val_y) = Math64x61.mul(grad[1], y)
    return (val_x + val_y)
end

func contribution{range_check_ptr}(grad: (felt, felt), x: felt, y: felt)->(res: felt):
    alloc_locals
    let (t) = compute_t(x, y)
    let (temp) = is_nn(t)

    if temp == TRUE:
        let (t_2) = Math64x61.mul(t, t)
        let (t_4) = Math64x61.mul(t_2, t_2)
        let (d) = dot(grad, x, y)
        return Math64x61.mul(t_4, d)
    else:
        return (0)
    end
end

func compute_t{range_check_ptr}(x: felt, y: felt) -> (t: felt):
    let (x_2) = Math64x61.mul(x, x)
    let (y_2) = Math64x61.mul(y, y)
    return (HALF - x_2 - y_2)
end

func random_szudzik{range_check_ptr}(x: felt, y: felt) -> (res: felt):
    let (x_felt) = Math64x61.toFelt(x)
    let (y_felt) = Math64x61.toFelt(y)
    let (temp) = szudzik(x_felt, y_felt)
    let (random) = lcg(temp, 2)
    let (_, res) = unsigned_div_rem(random, 8)
    return (res)
end

func determine_simplex{range_check_ptr}(x: felt, y: felt) -> (i: felt, j: felt):
    let (temp) = is_le(x, y)
    if temp == TRUE:
        return (0, Math64x61.ONE)
    else:
        return (Math64x61.ONE, 0)
    end
end

# x and y must be in 64.61 fixed point format
func noise{range_check_ptr}(x: felt, y: felt) -> (noise: felt):
    alloc_locals

    # skew input space
    let (s) = Math64x61.mul(x + y, F)
    let (i) = Math64x61.floor(x + s)
    let (j) = Math64x61.floor(y + s)

    let (t) = Math64x61.mul(G, i + j)
    let x0 = x - i + t
    let y0 = y - j + t

    # determine which simplex we are in
    let (i1, j1) = determine_simplex(x0, y0)

    let x1 = x0 - i1 + G
    let y1 = y0 - j1 + G
    let x2 = x0 - Math64x61.ONE + G2
    let y2 = y0 - Math64x61.ONE + G2

    # random gradient
    let (r0) = random_szudzik(i, j)
    let (r1) = random_szudzik(i+i1, j+j1)
    let (r2) = random_szudzik(i+Math64x61.ONE, j+Math64x61.ONE)

    let (g0) = select_grad2(r0)
    let (g1) = select_grad2(r1)
    let (g2) = select_grad2(r2)

    # contribution from the three corners
    let (n0) = contribution(g0, x0, y0)
    let (n1) = contribution(g1, x1, y1)
    let (n2) = contribution(g2, x2, y2)

    # return final value
    let (noise) = Math64x61.mul(n0 + n1 + n2, SEVENTY)
    return (noise)
end

func simplex_noise_bis{range_check_ptr}(
    x: felt, y: felt, o: felt, p: felt, a: felt, f: felt, max: felt, r: felt
) -> (res: felt):
    alloc_locals
    if o == 0:
        return Math64x61.div(r, max)
    else:
        let (x_f) = Math64x61.mul(x, f)
        let (y_f) = Math64x61.mul(y, f)
        let (f) = Math64x61.mul(f, TWO)
        let (n) = noise(x_f, y_f)
        let (temp) = Math64x61.mul(n, a)
        let max = max + a
        let (a) = Math64x61.mul(a, p)
        return simplex_noise_bis(x=x, y=y, o=o-1, p=p, a=a, f=f, max=max, r=r+temp)
    end
end

# x, y, persistence and frequency must be in 64.61 format
func simplex_noise{range_check_ptr}(
    x: felt, y: felt, octaves: felt, persistence: felt, frequency: felt
) -> (res: felt):
    return simplex_noise_bis(x, y, octaves, persistence, 2305843009213693952, frequency, 0, 0)
end