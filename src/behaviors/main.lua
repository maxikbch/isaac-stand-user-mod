
local IdleBehavior = require("src/behaviors/idle")
local RushBehavior = require("src/behaviors/rush")
local AttackBehavior = require("src/behaviors/attack")
local ReturnBehavior = require("src/behaviors/return")

---@param player EntityPlayer
---@param shootDir Vector
local function StandBehaviors(player, stand, shootDir)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	
	if standData.behavior == 'idle' then
		IdleBehavior(player, stand, shootDir)
	elseif standData.behavior == 'rush' then
		RushBehavior(player, stand, shootDir)
	elseif standData.behavior == 'attack' then
		AttackBehavior(player, stand, shootDir)
	elseif standData.behavior == 'return' then
		ReturnBehavior(player, stand, shootDir)
	end
end


return StandBehaviors




