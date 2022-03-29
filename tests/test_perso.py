"""test_perso.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "test_perso.cairo")

@pytest.mark.asyncio
async def test_valeurs_constantes():
    """Test grad3 method."""
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    sqrt_3 = await contract.sqrt_three().call()
    half = await contract.half().call()
    sixth = await contract.sixth().call()
    three = await contract.three().call()
    two = await contract.two().call()
    seventy = await contract.seventy().call()
    minus_two = await contract.minus_two().call()

    test_sqrt3 = await contract.test_sqrt_three().call()
    test_half = await contract.test_half().call()
    test_three = await contract.test_three().call()
    test_two = await contract.test_two().call()
    test_seventy = await contract.test_seventy().call()
    test_minus_two = await contract.test_minus_two().call()

    assert sqrt_3.result == (3993837248401023412,)
    assert half.result == (1152921504606846976,)
    assert sixth.result == (384307168202282325,)
    assert three.result == (6917529027641081856,)
    assert two.result == (4611686018427387904,)
    assert seventy.result == (161409010644958576640,)
    assert minus_two.result == (3618502788666131213697322783095070105623107215331596699968480370117444632577,)

    assert test_sqrt3.result == (3,)
    assert test_half.result == (1,)
    assert test_three.result == (3,)
    assert test_two.result == (2,)
    assert test_seventy.result == (70,)
    assert test_minus_two.result == (2,)

