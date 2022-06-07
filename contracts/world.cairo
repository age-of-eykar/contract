%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Plot:
    member owner : felt
    member structure : felt
    member availability : felt
end

struct Structure:
    member NONE : felt
    member SETTLER_CAMP : felt
    member LUMBER_CAMP : felt
end

@storage_var
func world(x : felt, y : felt) -> (plot : Plot):
end

@event
func world_update(x : felt, y : felt):
end

@view
func get_plot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt
) -> (plot : Plot):
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
