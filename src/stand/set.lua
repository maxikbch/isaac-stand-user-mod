
local character = require("src/character")

local function SetStand(player, stand)
    local playerData = player:GetData()

    if (player:GetPlayerType() ~= character.Type and player:GetPlayerType() ~= character.Type2) then
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
	if not playerData[stand.Id] or not playerData[stand.Id]:Exists() then
		playerData[stand.Id] = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, stand.Variant, 0, player.Position, Vector(0, 0), player)
	end
end

return SetStand