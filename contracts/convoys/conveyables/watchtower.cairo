%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.convoys.conveyables import Conveyable
from contracts.coordinates import Location

@storage_var
func belongings(convoy_id : felt, id : felt) -> (tower_id : felt):
end

@storage_var
func target(tower_id : felt) -> (loc : Location):
end

@storage_var
func free_tower_id() -> (tower_id : felt):
end

func _reserve_tower_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tower_id : felt
):
    let (tower_id) = free_tower_id.read()
    free_tower_id.write(tower_id + 1)
    return (tower_id + 1)
end

func _find_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, tower_id : felt, start_index : felt
) -> (id : felt):
    # Find the index of the tower in the convoy.
    #
    # Parameters:
    #   convoy_id: The ID of the convoy.
    #   tower_id: The ID of the tower.
    #   start_index: The index to start searching from (usually 0).
    #
    # Returns:
    #   The index of the tower in the convoy, or -1 if the tower is not in the convoy.
    let (found_tower_id) = belongings.read(convoy_id, start_index)
    if found_tower_id == tower_id:
        return (start_index)
    end
    if found_tower_id == 0:
        return (-1)
    end
    return _find_index(convoy_id, tower_id, start_index + 1)
end

func _get_belongings_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    convoy_id : felt, start_index : felt
) -> (amount : felt):
    # Get the amount of elements in the belongings array.
    #
    # Parameters:
    #     convoy_id: The ID of the convoy.
    #     start_index: The index of the first element to check.
    #
    # Returns:
    #     The amount of elements in the belongings array.
    let (value) = belongings.read(convoy_id, start_index)
    if value == 0:
        return (0)
    else:
        let (rest) = _get_belongings_length(convoy_id, start_index + 1)
        return (1 + rest)
    end
end

namespace WatchTower:
    # human
    const type = 'watchtower'

    func append_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt, conveyables_len : felt, conveyables : Conveyable*
    ) -> (conveyables_len : felt, conveyables : Conveyable*):
        # Append the meta data to the conveyables array if conveyable is part of the convoy
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #   conveyables_len: The length of the conveyables array
        #   conveyables: The conveyables array
        #
        # Returns:
        #   conveyables_len: The length of the conveyables array
        #   conveyables: The conveyables array

        return _append_meta(convoy_id, 0, conveyables_len, conveyables)
    end

    func _append_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt, index : felt, conveyables_len : felt, conveyables : Conveyable*
    ) -> (conveyables_len : felt, conveyables : Conveyable*):
        let (data) = belongings.read(convoy_id, index)
        if data == 0:
            let (conveyables) = alloc()
            return (0, conveyables)
        else:
            let (conveyables_len, conveyables) = _append_meta(convoy_id, index + 1)
            conveyables[conveyables_len] = Conveyable(type, data)
            return (conveyables + 1, conveyables)
        end
    end

    func protection{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt
    ) -> (protection : felt):
        # Get the protection of the convoy = 80% of target protection [TODO]
        #
        # Parameters:
        #   convoy_id: The ID of the convoy to check
        #
        # Returns:
        #   protection: The protection of the convoy
        return (1)
    end

    func set_target{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tower_id : felt, x : felt, y : felt
    ) -> ():
        # Set the target location of the tower.
        #
        # Parameters:
        #   tower_id: The ID of the tower.
        #   x: The x coordinate of the tower target.
        #   y: The y coordinate of the tower target.
        target.write(tower_id, Location(x, y))
        return ()
    end

    func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt, tower_id : felt
    ) -> ():
        # Remove the tower from the convoy.
        #
        # Parameters:
        #   convoy_id: The ID of the convoy.
        #   tower_id: The ID of the tower.
        let (index) = _find_index(convoy_id, tower_id, 0)
        if index == -1:
            assert 1 = 0
        end
        let size = _get_belongings_length(convoy_id, 0)
        _swap(convoy_id, index, size - 1)
        belongings.write(convoy_id, size - 1, 0)
        return ()
    end

    func _swap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        convoy_id : felt, tower_id1 : felt, tower_id2 : felt
    ) -> ():
        # Swap the two towers in the convoy.
        #
        # Parameters:
        #   convoy_id: The ID of the convoy.
        #   tower_id1: The ID of the first tower.
        #   tower_id2: The ID of the second tower.
        let (value1) = belongings.read(convoy_id, tower_id1)
        let (value2) = belongings.read(convoy_id, tower_id2)
        tower_id1.write(value2)
        tower_id2.write(value1)
        return ()
    end
end
