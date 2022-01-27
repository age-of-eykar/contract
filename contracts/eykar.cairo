# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import sqrt, unsigned_div_rem
from contracts.coordinates import get_distance

struct Plot:
    member owner : felt
    member dateOfOwnership : felt
    member structure : felt
end

@storage_var
func world(x : felt, y : felt) -> (plot : Plot):
end

@storage_var
func current_registration_id() -> (plot : Plot):
end

@view
func get_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x : felt, y : felt) -> (plot : Plot):
    let (plot) = world.read(x, y)
    return (plot)
end

@external
func mint_colony{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end

func find_next_location{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        id : felt, spacing : felt) -> (x : felt, y : felt, new_registration_id : felt):
        id_sqrt = sqrt(id)
        if id_sqrt >= 1 and id_sqrt % 2 == 0:
            id_sqrt -= 1

        let position_id = n - id_sqrt * id_sqrt
        id_sqrt += 1

        let circle_id = id_sqrt  / 2
        let side = position_id // id_sqrt
        let (_, position) = unsigned_div_rem(position_id, id_sqrt)


        let circle_modifier = ((1, 1), (1, -1), (-1, -1), (-1, 1))[side]
        let position_modifier = ((0, -1), (-1, 0), (0, 1), (1, 0))[side]

        return (
            spacing * (circle_modifier[0] * circle_id + position_modifier[0] * position),
            spacing * (circle_modifier[1] * circle_id + position_modifier[1] * position),
        )


    return ()
end