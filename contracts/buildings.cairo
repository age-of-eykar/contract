%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from contracts.convoys.library import assert_can_spend_convoy, has_convoy
from contracts.world import Plot, Structure, world, world_update
from contracts.colonies import find_redirected_colony
from contracts.map.biomes import assert_jungle_or_forest

@storage_var
func exploitation_start(x : felt, y : felt) -> (timestamp : felt):
end

@external
func build_lumber_camp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, x : felt, y : felt
) -> ():
    # Build a lumber camp at the given location.
    #
    # Parameters:
    #   convoy_id: The id of the convoy.
    #   x: The x coordinate of the lumber camp.
    #   y: The y coordinate of the lumber camp.
    alloc_locals
    let (test) = has_convoy(convoy_id, x, y)
    assert test = TRUE

    let (existing_plot : Plot) = world.read(x, y)
    if existing_plot.structure != Structure.NONE:
        if existing_plot.structure != Structure.SETTLER_CAMP:
            assert 1 = 0
        end
    end
    
    let (colony) = find_redirected_colony(existing_plot.owner)
    let (caller) = get_caller_address()
    assert colony.owner = caller
    assert_can_spend_convoy(convoy_id, caller)

    let (timestamp) = get_block_timestamp()
    assert_jungle_or_forest(x, y)

    # 300sec = 5min
    exploitation_start.write(x, y, timestamp + 300)
    world.write(x, y, Plot(colony.owner, Structure.LUMBER_CAMP, timestamp + 300))
    return ()
end
