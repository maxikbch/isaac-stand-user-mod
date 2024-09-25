

local StandEffects = {}

---@param player EntityPlayer
---@param en Entity
function StandEffects:TearEffects(player, stand, en)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
        en:AddConfusion(EntityRef(player), 40, false)
    else
        en:AddConfusion(EntityRef(player), 10, false)
    end
end


return StandEffects