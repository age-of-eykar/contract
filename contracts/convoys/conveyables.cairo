%lang starknet

struct FungibleConveyable:
    member type : felt
    member amount : felt
end

struct NonFungibleConveyable:
    member type : felt
    member id : felt
    member data : felt
end