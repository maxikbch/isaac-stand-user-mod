return function(jsf)
    return function(pickup, collider, low)
        if collider.Type ~= EntityType.ENTITY_PLAYER then
            return
        end

        if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then
            return
        end

        local discItem = pickup.SubType
        if not jsf:IsRegisteredDisc(discItem) then
            return
        end

        local player = collider:ToPlayer()
        if not player then
            return
        end

        jsf:SwapStandDisc(player, discItem)
    end
end
