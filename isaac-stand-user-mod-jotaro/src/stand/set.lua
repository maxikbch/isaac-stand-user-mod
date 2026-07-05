
local standItem = require("src/stand/item")

local function SetStand(player, stand)
    local playerData = player:GetData()

    if not player:HasCollectible(standItem) then
		if playerData[stand.Id] and playerData[stand.Id]:Exists() then
			playerData[stand.Id]:Remove()
			playerData[stand.Id] = nil
		end
		if playerData.mytgt and playerData.mytgt:Exists() then
			playerData.mytgt:Remove()
			playerData.mytgt = nil
		end
		return
	end
	if player:HasCollectible(standItem) and not playerData[stand.Id] or not playerData[stand.Id]:Exists() then
		local standEntity = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, stand.Variant, 0, player.Position, Vector(0, 0), player)
		playerData[stand.Id] = standEntity
		standEntity.Parent = player
	end

	if player:HasCollectible(standItem) and not playerData[stand.Id..".Item"] then		
		playerData[stand.Id..".Item"] = {}
	end
end

return SetStand