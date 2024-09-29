local standItem = require("src/stand/item")
local utils = require("src/utils")

---@param collectible CollectibleType
---@param player EntityPlayer
local function OnPickUpStandItem(collectible, player)
	local playerData = player:GetData()
	if playerData.StandDisc ~= nil then
		player:RemoveCollectible(playerData.StandDisc)
		local pedestal = utils:findClosestEmptyPedestal(player)
		if pedestal then
			local pickup = pedestal:ToPickup()
			if pickup then
				pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, playerData.StandDisc, true, false, false)
			end
		else
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, playerData.StandDisc, player.Position, Vector(0, 0), nil)
		end
	end
	playerData.StandDisc = collectible
end


---@param Type CollectibleType
---@param Player EntityPlayer
function OnPickUpItem(Type, Charge, FirstTime, Slot, VarData, Player)
	if Type == standItem then
		OnPickUpStandItem(Type, Player)
	end
    return Type
end


return OnPickUpItem