%lang starknet

from starkware.cairo.common.math import sqrt, unsigned_div_rem
from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Location:
    member x : felt
    member y : felt
end

func get_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        xmin : felt, ymin : felt, xmax : felt, ymax : felt) -> (distance : felt):
    # Calculate an approximated ineteger distance between two Cartesian coordinates
    #
    #   Parameters:
    #       xmin (felt): value on the x axis of the first point
    #       ymin (felt): value on the y axis of the first point
    #       xmax (felt): value on the x axis of the second point
    #       ymax (felt): value on the y axis of the second point
    #
    #   Returns:
    #       distance (felt): Estimated distance between the two points
    let x_distance = xmax - xmin
    let y_distance = ymax - ymin
    let (distance) = sqrt(x_distance *  x_distance + y_distance * y_distance)
    return (distance)
end

func spiral{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        n : felt, spacing : felt) -> (x : felt, y : felt):
    if n == 0:
        return (0, 0)
    end

    let (base_id) = sqrt(n)
    let (prev_circle_id, _) = unsigned_div_rem(base_id - 1, 2)
    let id = prev_circle_id + 1
    let prev_side_size = 2 * prev_circle_id + 1
    let additional_cells = n - prev_side_size * prev_side_size
    let side_size = 2 * id
    let (side_id, next_cells) = unsigned_div_rem(additional_cells, side_size)
    if side_id == 0:
        return ((next_cells - id + 1) * (spacing + 1), id * (spacing + 1))
    end
    if side_id == 1:
        return (id * (spacing + 1), (id - 1 - next_cells) * (spacing + 1))
    end
    if side_id == 2:
        return ((id - 1 - next_cells) * (spacing + 1), (-id) * (spacing + 1))
    end
    if side_id == 3:
        return ((-id) * (spacing + 1), (next_cells - id + 1) * (spacing + 1))
    end

    with_attr error_message("x must not be zero."):
        assert 1 = 0
        return (0, 0)
    end
end
