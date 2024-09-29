local SETTINGS = require("src/constants/settings")
local STATS = require("src/constants/stats")
local stand = require("src/constants/stand")
local standItem = require("src/stand/item")

local utils = require("src/utils")

local StandMeter = 
{
	StandMeter = Sprite(),
	charging = 'charging',
	charged = 'charged',
	uncharging = 'uncharging',
}

local x1 = 60
local x2 = 120
local y1 = 50
local y2 = 100

local offset = {
	Player0 = {	
		X = x1, 
		Y = y1
	},
	Player1 = {	
		X = x2, 
		Y = y1
	},
	Player2 = {	
		X = x1, 
		Y = y2
	},
	Player3 = {	
		X = x2, 
		Y = y2
	}
}
  
StandMeter.StandMeter:Load("gfx/stand_user/stand_meter.anm2", true)
StandMeter.StandMeter.PlaybackSpeed = 0.15

---@param player EntityPlayer
local function ForEachPlayer(player, index)
	
	local playerData = player:GetData()

	if SETTINGS.HasUltimate and player:HasCollectible(standItem) and playerData[stand.Id..".Item"] then
		local meter = StandMeter.StandMeter
		
		local standItemData = playerData[stand.Id..".Item"]

		local charge = standItemData.UltimateCharge or 0
		local duration = standItemData.UltimateDuration or 0

		if duration > 0 then 
			meter:SetFrame(StandMeter.uncharging, 22 - math.floor(duration / STATS.UltimateDuration * 22))
		elseif charge == STATS.UltimateMaxCharge then
			if not meter:IsPlaying(StandMeter.charged) then
				meter:Play(StandMeter.charged, true)
			end
		else
			meter:SetFrame(StandMeter.charging, math.floor(charge / STATS.UltimateMaxCharge * 22))
		end

		if offset["Player"..index] then
			meter:Render(Vector(offset["Player"..index].X , offset["Player"..index].Y), Vector(0, 0), Vector(0, 0))
		end

		if not Game():IsPaused() then
			meter:Update()
		end
	end
end

local function onRender()
	utils:ForAllPlayers(ForEachPlayer)
end

return onRender