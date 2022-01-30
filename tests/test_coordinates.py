"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "coordinates.cairo")

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
    assert l.result == (0,0)

    l = await contract.spiral(1, 0).call()
    assert l.result == (0,1)

    l = await contract.spiral(2, 0).call()
    assert l.result == (1,1)

    l = await contract.spiral(3, 0).call()
    assert l.result == (1,0)