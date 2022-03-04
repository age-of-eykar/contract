%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from contracts.coordinates import spiral, get_distance
from contracts.colonies import Colony, get_colony, create_colony, redirect_colony

struct Plot:
    member owner : felt
    member dateOfOwnership : felt
    member structure : felt
end

@storage_var
func world(x : felt, y : felt) -> (plot : Plot):
end

@view
func get_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x : felt, y : felt) -> (plot : Plot):
    # Gets a plot object at the given coordinates
    #
    #   Parameters:
    #       x (felt): The x coordinate of the plot
    #       y (felt): The y coordinate of the plot
    #
    #   Returns:
    #       plot (Plot): The plot object at the given coordinates
    let (plot) = world.read(x, y)
    return (plot)
end

@storage_var
func current_registration_id() -> (id : felt):
end

func _get_next_available_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        n : felt) -> (x : felt, y : felt, n : felt):
    let (x, y) = spiral(n, 16)
    let (plot) = world.read(x, y)
    if plot.owner == 0:
        return (x, y, n)
    else:
        return _get_next_available_plot(n + 1)
    end
end

@storage_var
func _player_colonies_storage(player : felt, index : felt) -> (colony_id : felt):
end

@storage_var
func _player_colonies_len(player : felt) -> (colonies_length : felt):
end

func _get_player_colonies{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player : felt, colonies_index : felt, colonies_len : felt, colonies : felt*):
    if colonies_index == colonies_len:
        return ()
    end

    let (colony) = _player_colonies_storage.read(player, colonies_index)
    assert colonies[colonies_index] = colony

    _get_player_colonies(player, colonies_index + 1, colonies_len, colonies)
    return ()
end

@view
func get_player_colonies{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player : felt) -> (colonies_len : felt, colonies : felt*):
    alloc_locals
    let (colonies) = alloc()
    let (colonies_len) = _player_colonies_len.read(player)
    if colonies_len == 0:
        return (colonies_len, colonies)
    end

    # Recursively add colonies id from storage to the colonies array
    _get_player_colonies(player, 0, colonies_len, colonies)
    return (colonies_len, colonies)
end

func add_colony_to_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player : felt, colony_id : felt) -> ():
    let (id) = _player_colonies_len.read(player)
    _player_colonies_len.write(player, id + 1)
    _player_colonies_storage.write(player, id, colony_id)
    return ()
end

func _merge_util{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, x : felt, y : felt, n : felt) -> (id : felt, plots_amount : felt):
    alloc_locals
    if n == 0:
        return (0, 0)
    end

    let (x_shift, y_shift) = spiral(n, 0)
    let (plot) = get_plot(x + x_shift, y + y_shift)
    let (colony) = get_colony(plot.owner)

    let (next_best_id, next_best_plots_amount) = _merge_util(owner, x, y, n - 1)
    if colony.owner != owner:
        return (next_best_id, next_best_plots_amount)
    end

    # if next_best_plots_amount > colony.plots_amount
    let (sup) = is_le(next_best_plots_amount, colony.plots_amount)
    if sup == 0:
        if colony.redirection != 0:
            redirect_colony(colony.redirection, next_best_id)
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
        return (next_best_id, next_best_plots_amount)
    else:
        if next_best_id != 0:
            if colony.redirection != 0:
                redirect_colony(next_best_id, colony.redirection)
                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr
            else:
                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr
            end
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
        return (colony.redirection, colony.plots_amount)
    end
end

func merge{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, x : felt, y : felt) -> (id : felt):
    # Merges colonies around a specific plot
    #
    # Parameters:
    #     owner (felt): The owner of the plot
    #     x (felt): The x coordinate of the plot
    #     y (felt): The y coordinate of the plot
    #
    # Returns:
    #     id (felt): The id of the redirected colony
    let (id, plots_amount) = _merge_util(owner, x, y, 9)
    return (id)
end

@external
func mint_plot_with_new_colony{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt):
    # Mints a plot on the next available location of the spawn spiral
    alloc_locals
    let (n) = current_registration_id.read()
    let (x, y, m) = _get_next_available_plot(n)
    current_registration_id.write(m + 1)

    let (player) = get_caller_address()
    let (colony_id) = merge(player, x, y)
    let (timestamp) = get_block_timestamp()
    if colony_id == 0:
        let (colony) = create_colony(name, player, x, y)
        add_colony_to_player(player, colony.redirection)
        world.write(x, y, Plot(owner=colony.redirection, dateOfOwnership=timestamp, structure=1))
    else:
        world.write(x, y, Plot(owner=colony_id, dateOfOwnership=timestamp, structure=1))
    end
    return ()
end
