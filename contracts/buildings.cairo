%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from contracts.convoys.library import assert_can_spend_convoy, contains_convoy
from contracts.world import Plot, Structure, world, world_update, get_plot

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
    let (test) = contains_convoy(convoy_id, x, y)
    assert test = TRUE

    let (existing_plot : Plot) = world.read(x, y)
    if existing_plot.structure != Structure.NONE:
        if existing_plot.structure != Structure.SETTLER_CAMP:
            assert 1 = 0
        end
    end

    let (caller) = get_caller_address()
    assert existing_plot.owner = caller
    assert_can_spend_convoy(convoy_id, caller)

    let (timestamp) = get_block_timestamp()

    # 300sec = 5min
    exploitation_start.write(x, y, timestamp + 300)
    world.write(x, y, Plot(convoy_id, Structure.LUMBER_CAMP, timestamp + 300))
    return ()
end
