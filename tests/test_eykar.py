"""contract.cairo test file."""
import os
from starknet_util import Felt

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "eykar.cairo")


@pytest.mark.asyncio
async def test_mint_plot():
    """Test mint_plot method."""

    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
    l = await contract.mint_plot_with_new_colony(0).invoke()
