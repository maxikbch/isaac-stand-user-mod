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
local function ChargeStandMeter(entity, source, sourceType, damageFlags)

	if source and source:Exists() and Settings.HasSuper and entity:IsVulnerableEnemy() then
	
		if source.Type == EntityType.ENTITY_PLAYER then

			local player = source:ToPlayer()
			local playerData = player and player:GetData() or {}
			local standItemData = playerData[stand.Id..".Item"]

			if playerData.StandDisc == standItem then
				if not standItemData.SuperCharge then standItemData.SuperCharge = 0 end
				
				if standItemData.SuperCharge < STATS.SuperMaxCharge 
				and (not standItemData.SuperCooldown or standItemData.SuperCooldown == 0) 
				and (not standItemData.SuperDuration or standItemData.SuperDuration == 0) 
				and not standItemData.PowerOn then
					standItemData.SuperCharge = math.min(STATS.SuperMaxCharge, standItemData.SuperCharge + ChargePoints(sourceType))
				end
			end

			return {player, standItemData}

		elseif source.SpawnerEntity then
			local player = source.SpawnerEntity or {}
			ChargeStandMeter(entity, player, sourceType, damageFlags)
			
		elseif source.Type == EntityType.ENTITY_FAMILIAR then
			local familiar = source:ToFamiliar()
			local player = familiar and familiar.Player or {}
			ChargeStandMeter(entity, player, sourceType, damageFlags)
		end
	end	
end

---@param entity Entity
---@param source EntityRef
local function OnEntityTakeDamage(entity, damageAmount, damageFlags, source, countdownFrames)
	local data = ChargeStandMeter(entity, source.Entity, source.Type, damageFlags)

	local player = (data and data.player) or nil
	local standItemData = (data and data.standItemData) or nil

	if standItemData and standItemData.SuperDuration and standItemData.SuperDuration > 0 
	and entity.Type ~= EntityType.ENTITY_PLAYER and damageFlags & DamageFlag.DAMAGE_LASER ~= 0 
	and player and not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
		return false
	end
end

return OnEntityTakeDamage