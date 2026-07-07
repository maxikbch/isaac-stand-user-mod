local StandEffects = {}

function StandEffects:TearEffects(player, standDef, en)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
        en:AddConfusion(EntityRef(player), 40, false)
    else
        en:AddConfusion(EntityRef(player), 10, false)
    end
end

function StandEffects:ToGridEntities(player, standDef, en)
    if en.State then
        en:Destroy()
    end
end

return StandEffects
