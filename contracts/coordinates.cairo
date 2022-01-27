%lang starknet
from starkware.cairo.common.math import sqrt
from starkware.cairo.common.cairo_builtins import HashBuiltin

@view
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
    let (distance) = sqrt(x_distance * x_distance + y_distance * y_distance)
    return (distance)
end
