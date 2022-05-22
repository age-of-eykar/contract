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
    await contract.mint(123).invoke(caller_address=player)
    await contract.mint(456).invoke(caller_address=player)
    execution_info = await contract.get_player_colonies(player).call()
    assert execution_info.result[0] == [1, 2]


@pytest.mark.asyncio
async def test_extend():
    """Test extend method."""

    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    # First let's mint a plot and a new colony
    execution_info = await contract.get_player_colonies(0).call()
    assert execution_info.result == ([],)
    player = 1
    await contract.mint(123).invoke(caller_address=player)
    execution_info = await contract.get_player_colonies(player).call()
    assert execution_info.result[0] == [1]
    await contract.extend(0, 1, 0, 0, 0).invoke(caller_address=player)
    execution_info = await contract.get_plot(0, 1).call()
    plot = execution_info.result.plot
    assert plot.owner == 1
    assert plot.structure == 2
