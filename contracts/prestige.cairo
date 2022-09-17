%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

# a player can be a guild

@storage_var
func prestige_per_player(player : felt) -> (prestige : felt):
end

func add_prestige{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player : felt, prestige : felt
) -> ():
    let (current_prestige) = prestige_per_player.read(player)

    return ()
end
