local Settings = require("src/constants/settings")
local STATS = require("src/constants/stats")
local stand = require("src/constants/stand")
local standItem = require("src/stand/item")

---@param sourceType EntityType
local function ChargePoints(sourceType)
	
	if sourceType == EntityType.ENTITY_BOMB then return 4 end
	return 1
end


---@param entity Entity
---@param source Entity
---@param sourceType EntityType
local function ChargeStandMeter(entity, source, sourceType)

	if source and source:Exists() and Settings.HasSuper and entity:IsVulnerableEnemy() then
	
		if source.Type == EntityType.ENTITY_PLAYER then

			local player = source:ToPlayer()
			local playerData = player and player:GetData() or {}
			local standItemData = playerData[stand.Id..".Item"]

			if playerData.StandDisc == standItem then
				if not standItemData.SuperCharge then standItemData.SuperCharge = 0 end
				
				if standItemData.SuperCharge < STATS.SuperMaxCharge then
					standItemData.SuperCharge = math.min(STATS.SuperMaxCharge, standItemData.SuperCharge + ChargePoints(sourceType))
				end
			end

		elseif source.SpawnerEntity then
			local player = source.SpawnerEntity or {}
			ChargeStandMeter(entity, player, sourceType)
			
		elseif source.Type == EntityType.ENTITY_FAMILIAR then
			local familiar = source:ToFamiliar()
			local player = familiar and familiar.Player or {}
			ChargeStandMeter(entity, player, sourceType)
		end
	end	
end

---@param entity Entity
---@param source EntityRef
local function OnEntityTakeDamage(entity, damageAmount, damageFlags, source, countdownFrames)
	ChargeStandMeter(entity, source.Entity, source.Type)
end

return OnEntityTakeDamage