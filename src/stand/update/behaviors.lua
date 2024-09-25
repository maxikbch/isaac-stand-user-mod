
local IdleBehavior = require("src/stand/update/behaviors/idle")
local RushBehavior = require("src/stand/update/behaviors/rush")
local AttackBehavior = require("src/stand/update/behaviors/attack")
local ReturnBehavior = require("src/stand/update/behaviors/return")

---@param player EntityPlayer
---@param shootDir Vector
local function StandBehaviors(player, stand, shootDir, roomframes)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	
	if standData.behavior == 'idle' then
		IdleBehavior(player, stand, shootDir, roomframes)
	elseif standData.behavior == 'rush' then
		RushBehavior(player, stand, shootDir, roomframes)
	elseif standData.behavior == 'attack' then
		AttackBehavior(player, stand, shootDir, roomframes)
	elseif standData.behavior == 'return' then
		ReturnBehavior(player, stand, shootDir, roomframes)
	end
end


return StandBehaviors




