from math import sqrt

frac_part = 2 ** 61
int_part = 2 ** 64
P = 2 ** 251 + 17 * 2 ** 192 + 1

def from_64x61_to_float(n, max_int=100):
    integer = n // frac_part
    fraction = n % frac_part
    res = integer + fraction / frac_part
    return res if res < max_int else from_64x61_to_float(n - P)

def from_float_to_64x61(f):
    return int(f * frac_part) if f > 0 else (P - int(abs(f) * frac_part)) % P

print(from_float_to_64x61(0.5))
print(from_float_to_64x61(0.012))
print(from_float_to_64x61(1))
print(from_float_to_64x61(0.015))
