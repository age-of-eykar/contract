"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.

CONTRACT_FILE = os.path.join("contracts", "simplex_noise.cairo")

@pytest.mark.asyncio
async def test_grad3():
    """Test grad3 method."""
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    l1 = await contract.grad3(0, 0).call()
    l2 = await contract.grad3(0, 2).call()

    assert l1.result == (1,)
    assert l2.result == (0,)


@pytest.mark.asyncio
async def test_noise():
    """Test noise method."""
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    l1 = await contract.test_simplex(0, 0).call()
    l2 = await contract.test_simplex(0, 2).call()

    print(l1.result)
    print(l2.result)
    
    assert l1.result == (0,)
    assert l2.result == (0,)