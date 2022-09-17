%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from contracts.map.coordinates import spiral, get_distance
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from contracts.map.world import world

struct Colony {
    name: felt,  // string
    owner: felt,  // address
    x: felt,  // place of power location
    y: felt,  // place of power location
    plots_amount: felt,
    redirection: felt,  // redirect to itself if is destination
}

@storage_var
func colonies(id: felt) -> (colony: Colony) {
}

func find_redirected_colony{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: felt
) -> (colony: Colony) {
    // Gets the colony object after multiple redirections
    //
    // Parameters:
    //       id (felt): the colony id
    //
    //   Returns:
    //       colony (felt): struct after redirections
    let (colony) = colonies.read(id - 1);
    if (colony.redirection != id) {
        return find_redirected_colony(colony.redirection);
    } else {
        return (colony,);
    }
}

func create_colony{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, owner: felt, x: felt, y: felt
) -> (colony: Colony) {
    let (id) = _find_available_colony_id(1);
    let colony = Colony(name, owner, x, y, plots_amount=0, redirection=id);
    colonies.write(id - 1, colony);
    return (colony,);
}

func redirect_colony{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: felt, new_id: felt
) -> () {
    alloc_locals;
    let (old_colony) = find_redirected_colony(id);
    let (new_colony) = find_redirected_colony(new_id);
    colonies.write(
        id - 1,
        Colony(
        old_colony.name, old_colony.owner, old_colony.x, old_colony.y,
        plots_amount=old_colony.plots_amount,
        redirection=new_colony.redirection),
    );
    return ();
}

func _find_available_colony_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    start: felt
) -> (id: felt) {
    let (colony) = colonies.read(start - 1);
    if (colony.owner == 0) {
        if (start == 1) {
            return (1,);
        }
        return _find_available_colony_id_dichotomia(start / 2, start);
    } else {
        return _find_available_colony_id(2 * start);
    }
}

func _find_available_colony_id_dichotomia{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(start: felt, last: felt) -> (id: felt) {
    if (start == last) {
        return (start,);
    } else {
        let (id, _) = unsigned_div_rem(start + last, 2);
        let (colony) = colonies.read(id - 1);
        if (colony.owner == 0) {
            return _find_available_colony_id_dichotomia(start, id);
        } else {
            return _find_available_colony_id_dichotomia(id + 1, last);
        }
    }
}

//
// Colonies
//

@storage_var
func current_registration_id() -> (id: felt) {
}

func _get_next_available_plot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    n: felt
) -> (x: felt, y: felt, n: felt) {
    let (x, y) = spiral(n, 16);
    let (plot) = world.read(x, y);
    if (plot.owner == 0) {
        return (x, y, n);
    } else {
        return _get_next_available_plot(n + 1);
    }
}

@storage_var
func _player_colonies_storage(player: felt, index: felt) -> (colony_id: felt) {
}

func _get_player_colonies{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, colonies_index: felt
) -> (colonies_len: felt, found_colonies: felt*) {
    alloc_locals;
    let (colony_id) = _player_colonies_storage.read(player, colonies_index);

    if (colony_id == 0) {
        let (found_colonies) = alloc();
        return (0, found_colonies);
    }

    let (colonies_len, found_colonies) = _get_player_colonies(player, colonies_index + 1);
    let (colony: Colony) = colonies.read(colony_id - 1);
    let redirect: felt = colony.redirection;

    if (colony.redirection == colony_id) {
        assert [found_colonies] = colony_id;
        return (colonies_len + 1, found_colonies + 1);
    } else {
        return (colonies_len, found_colonies);
    }
}

func _colonies_amount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, colonies_index: felt
) -> (amount: felt) {
    let (colony) = _player_colonies_storage.read(player, colonies_index);
    if (colony == 0) {
        return (0,);
    }
    let (remaining) = _colonies_amount(player, colonies_index + 1);
    return (1 + remaining,);
}

func add_colony_to_player{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: felt, colony_id: felt
) -> () {
    let (id) = _colonies_amount(player, 0);
    _player_colonies_storage.write(player, id, colony_id);
    return ();
}

func _merge_util{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, x: felt, y: felt, n: felt
) -> (id: felt, plots_amount: felt) {
    alloc_locals;
    if (n == 0) {
        return (0, 0);
    }

    let (x_shift, y_shift) = spiral(n, 0);
    let (plot) = world.read(x + x_shift, y + y_shift);
    let (colony) = find_redirected_colony(plot.owner);

    let (next_best_id, next_best_plots_amount) = _merge_util(owner, x, y, n - 1);
    if (colony.owner != owner) {
        return (next_best_id, next_best_plots_amount);
    }

    // if next_best_plots_amount > colony.plots_amount
    let sup = is_le(next_best_plots_amount, colony.plots_amount);
    if (sup == 0) {
        if (colony.redirection != 0) {
            redirect_colony(colony.redirection, next_best_id);
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        return (next_best_id, next_best_plots_amount);
    } else {
        if (next_best_id != 0) {
            if (colony.redirection != 0) {
                redirect_colony(next_best_id, colony.redirection);
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        return (colony.redirection, colony.plots_amount);
    }
}

func merge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, x: felt, y: felt
) -> (id: felt) {
    // Merges colonies around a specific plot
    //
    // Parameters:
    //     owner (felt): The owner of the plot
    //     x (felt): The x coordinate of the plot
    //     y (felt): The y coordinate of the plot
    //
    // Returns:
    //     id (felt): The id of the redirected colony
    let (id, plots_amount) = _merge_util(owner, x, y, 9);
    return (id,);
}
