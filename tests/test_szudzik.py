"""test_perso.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "szudzik.cairo")


@pytest.mark.asyncio
async def test_random_felt():
    """Test random_felt method."""
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    random_12_0 = await contract.random_felt(0, -4, 1, 0, 12).call()
    random_12_1 = await contract.random_felt(0, -4, 1, 0, 12).call()
    random_1 = await contract.random_felt(989, 56, 1, 0, 1).call()
    random_50_0 = await contract.random_felt(5442, -4322, 1, 0, 50).call()
    random_50_1 = await contract.random_felt(3, -9999, 1, 0, 50).call()

    assert random_12_0.result == random_12_1.result
    assert random_12_0.result <= (12,)
    assert random_1.result == (1,) or random_1.result == (0,)
    assert random_50_0.result <= (50,)
    assert random_50_0.result != random_50_1.result


#@pytest.mark.asyncio
#async def test_distribution():
#    """Test distribution."""
#    starknet = await Starknet.empty()
#    contract = await starknet.deploy(
#        source=CONTRACT_FILE,
#    )

#    somme = 0
#    moyenne = 50
#    y = 0
#    for x in range(1000):
#        somme += await contract.random_felt(x, y, 1, 0, 100).call()
#    
#    assert abs(somme/1000 - moyenne) < 100