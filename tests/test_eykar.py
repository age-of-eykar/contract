"""contract.cairo test file."""
import os
from starknet_util import Felt

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "eykar.cairo")

@pytest.mark.asyncio
async def test_get_player_colonies():
    """Test mint_plot method."""

    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
    execution_info = await contract.get_player_colonies(0).call()
    assert execution_info.result == ([],)
    await contract.mint_plot_with_new_colony(123).invoke()
    execution_info = await contract.get_player_colonies(contract.contract_address).call()
    assert len(execution_info.result[0]) == 1

@pytest.mark.asyncio
async def test_mint_plot():
    """Test mint_plot method."""

    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
    l = await contract.mint_plot_with_new_colony(0).invoke()
