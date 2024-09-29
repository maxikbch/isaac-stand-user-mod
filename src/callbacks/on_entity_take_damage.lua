local SETTINGS = require("src/constants/settings")
local STATS = require("src/constants/stats")
local stand = require("src/constants/stand")
local standItem = require("src/stand/item")

local utils = require("src/utils")

local function ChargeStandMeter(entity)
	if SETTINGS.HasUltimate and entity:IsVulnerableEnemy() then

		utils:ForAllPlayers(function (player, index)

			local playerData = player:GetData()
			local standItemData = playerData[stand.Id..".Item"]

			if playerData.StandDisc == standItem then
				if not standItemData.UltimateCharge then standItemData.UltimateCharge = 0 end
				
				if standItemData.UltimateCharge < STATS.UltimateMaxCharge then
					standItemData.UltimateCharge = math.min(STATS.UltimateMaxCharge, standItemData.UltimateCharge + 1)
				end
			end

		end)

	end	
end

---@param entity Entity
local function OnEntityTakeDamage(entity, damageAmount, damageFlags, source, countdownFrames)
	ChargeStandMeter(entity)
end

return OnEntityTakeDamage