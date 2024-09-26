
local utils = require("src/utils")

local STATS = require("src/constants/stats")
local SETTINGS = require("src/constants/settings")

local function DoUltimate(player, stand)
    print("ULTIMATE!")
    --stand.room2 = Game():GetLevel():GetCurrentRoomIndex()
    --stand.Freeze = 165
    --sfx:Play(snd.STOP_TIME,2,0,false,1)
    --sfx:Play(snd.STZW,2,0,false,1)
    --stand.savedTime = game.TimeCounter
    --music:Disable()
    --StandIsCharged = false
    stand.UltimateCharge = 0
    --stand.StandActive = true
    stand.UltimateCooldown = STATS.UltimateCooldown
end

local function UpdateUltimate(player, stand)
	if stand.UltimateCooldown and stand.UltimateCooldown > 0 then
        stand.UltimateCooldown = math.max(0, stand.UltimateCooldown - 1)
    end
end

return function (player, stand)
	local playerData = player:GetData()
	local controler = player.ControllerIndex
    local stand = playerData[stand.Id]:GetData()
    
    if Input.IsButtonPressed(SETTINGS.KEY_ULTIMATE, controler) 
	or (SETTINGS.ControllerOn and Input.IsActionTriggered(ButtonAction.ACTION_DROP, controler))
    then
		if stand.UltimateCharge == STATS.UltimateMaxCharge then
            DoUltimate(player, stand)
        end
    end

    UpdateUltimate(player, stand)
end