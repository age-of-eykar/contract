P = 2**251 + 17 * 2**192 + 1


class Felt:
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return str(self.value)

    def __eq__(self, other):
        return (self.value - other.value) % P == 0

    def __add__(self, other):
        return Felt((self.value + other.value) % P)

    def __sub__(self, other):
        return Felt((self.value - other.value) % P)

    def __mul__(self, other):
        return Felt((self.value * other.value) % P)

    def __truediv__(self, other):
        raise ValueError

    def __floordiv__(self, other):
        return Felt((self.value // other.value) % P)
