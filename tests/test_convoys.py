"""convoys.cairo test file."""
import os
from starknet_util import Felt

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "convoys.cairo")


@pytest.mark.asyncio
async def test_get_movability():
    """Test get_movability method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    d = await contract.get_movability(0).call()
    assert  Felt(d.result[0]) == Felt(1)

    d = await contract.get_movability(1).call()
    assert  Felt(d.result[0]) == Felt(-1)

    d = await contract.get_movability(2).call()
    assert  Felt(d.result[0]) == Felt(-2)

    d = await contract.get_movability(3).call()
    assert  Felt(d.result[0]) == Felt(5)


@pytest.mark.asyncio
async def test_get_speed():
    """Test get_speed method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    d = await contract.get_speed(0).call()
    assert  Felt(d.result[0]) == Felt(1)

    d = await contract.get_speed(1).call()
    assert  Felt(d.result[0]) == Felt(-1)

    d = await contract.get_speed(2).call()
    assert  Felt(d.result[0]) == Felt(-1)

    d = await contract.get_speed(3).call()
    assert  Felt(d.result[0]) == Felt(2)
