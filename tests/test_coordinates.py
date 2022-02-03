"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "coordinates.cairo")


def felt_equal(v1, v2):
    """
    Checks if two felt vectors are equal.

    Args:
        v1 (int iterable): The first vector.
        v2 (int iterable): The second vector.

    Returns:
        bool: True if the two vectors are equal, False otherwise.
    """
    P = 2**251 + 17 * 2**192 + 1
    if len(v1) != len(v2):
        return False
    for x, y in zip(v1, v2):
        if (P + (x - y)) % P != 0:
            return False
    return True


@pytest.mark.asyncio
async def test_get_distance():
    """Test get_distance method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    d = await contract.get_distance(0, 0, 10, 10).call()
    assert d.result == (14,)

    d = await contract.get_distance(-5, -5, 5, 5).call()
    assert d.result == (14,)


@pytest.mark.asyncio
async def test_spiral():
    """Test spiral method."""

    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    l = await contract.spiral(0, 0).call()
    assert felt_equal(l.result, (0, 0))

    l = await contract.spiral(1, 0).call()
    assert felt_equal(l.result, (0, 1))

    l = await contract.spiral(2, 0).call()
    assert felt_equal(l.result, (1, 1))

    l = await contract.spiral(3, 0).call()
    assert felt_equal(l.result, (1, 0))

    l = await contract.spiral(4, 0).call()
    assert felt_equal(l.result, (1, -1))

    l = await contract.spiral(5, 0).call()
    assert felt_equal(l.result, (0, -1))

    l = await contract.spiral(6, 0).call()
    assert felt_equal(l.result, (-1, -1))

    l = await contract.spiral(9, 0).call()
    assert felt_equal(l.result, (-1, 2))

    l = await contract.spiral(12, 0).call()
    assert felt_equal(l.result, (2, 2))