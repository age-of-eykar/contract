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
    execution_info = await contract.get_player_colonies(0).call()
    assert execution_info.result == ([],)
    player = 1
    await contract.mint_plot_with_new_colony(123).invoke(caller_address=player)
    await contract.mint_plot_with_new_colony(456).invoke(caller_address=player)
    execution_info = await contract.get_player_colonies(player).call()
    assert execution_info.result[0] == [1, 2]
