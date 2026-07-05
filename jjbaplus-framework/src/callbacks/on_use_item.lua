return function()
    return function(ItemID, RNG, player, Flags, Slot, CustomVarData)
        if ItemID == CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS then
            player:GetData().usedBoxOfFriends = true
        end
        return true
    end
end
