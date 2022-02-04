# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from contracts.coordinates import spiral, get_distance

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

struct Colony:
    member name : felt  # string
    member owner : felt  # address
    member x : felt  # place of power location
    member y : felt  # place of power location
    member plots_amount : felt
    member people : felt
    member food : felt
    member wood : felt
    member ores : felt
    member redirection : felt  # redirect to itself if is destination
end

@storage_var
func colonies(id : felt) -> (colony : Colony):
end

@view
func get_colony{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt) -> (
        colony : Colony):
    # Gets the colony object after multiple redirections
    #
    #   Parameters:
    #       id (felt): the colony id
    #
    #   Returns:
    #       colony (felt): struct after redirections
    let (colony) = colonies.read(id - 1)
    if colony.redirection != id:
        return get_colony(colony.redirection)
    else:
        return (colony)
    end
end

@storage_var
func current_registration_id() -> (id : felt):
end

func _get_next_available_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        n : felt) -> (x : felt, y : felt, n : felt):
    let (x, y) = spiral(n, 0)
    let (plot) = world.read(x, y)
    if plot.owner == 0:
        return (x, y, n)
    else:
        return _get_next_available_plot(n + 1)
    end
end

func _find_available_colony_id_dichotomia{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        start : felt, last : felt) -> (id : felt):
    if start == last:
        return (start)
    else:
        let (id, _) = unsigned_div_rem(start + last, 2)
        let (colony) = colonies.read(id - 1)
        if colony.owner == 0:
            return _find_available_colony_id_dichotomia(id, last)
        else:
            return _find_available_colony_id_dichotomia(start, id)
        end
    end
end

func _find_available_colony_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        start : felt) -> (id : felt):
    let (colony) = colonies.read(start - 1)
    if colony.owner == 0:
        return _find_available_colony_id_dichotomia(start / 2, start)
    else:
        return _find_available_colony_id(2 * start)
    end
end

func _create_colony{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, owner : felt, x : felt, y : felt) -> (id : Colony):
    let (id) = _find_available_colony_id(1)
    let colony = Colony(
        name, owner, x, y, plots_amount=0, people=0, food=0, wood=0, ores=0, redirection=id)
    colonies.write(id - 1, colony)
    return (colony)
end

@storage_var
func _player_colonies_storage(player : felt, index : felt) -> (colony_id : felt):
end

@storage_var
func player_colonies(player : felt) -> (colonies_length : felt):
end

func add_colony_to_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player : felt, colony_id : felt) -> ():
    let (id) = player_colonies.read(player)
    player_colonies.write(player, id + 1)
    _player_colonies_storage.write(player, id, colony_id)
    return ()
end

@external
func mint_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Mints a plot on the next available location of the spawn spiral
    let (n) = current_registration_id.read()
    let (x, y, n) = _get_next_available_plot(n)
    current_registration_id.write(n + 1)
    world.write(x, y, Plot(owner=1, dateOfOwnership=1, structure=1))
    return ()
end
