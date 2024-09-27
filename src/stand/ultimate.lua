
local stand = require("src/constants/stand")
local STATS = require("src/constants/stats")
local SETTINGS = require("src/constants/settings")
local standItem = require("src/stand/item")

local function DoUltimate(player, standEntity)
    local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"]

    --stand.room2 = Game():GetLevel():GetCurrentRoomIndex()
    standItemData.UltimateDuration = STATS.UltimateDuration
    --sfx:Play(snd.STOP_TIME,2,0,false,1)
    --sfx:Play(snd.STZW,2,0,false,1)
    --stand.savedTime = game.TimeCounter
    --music:Disable()
    --StandIsCharged = false
    standItemData.UltimateCharge = 0
    --stand.StandActive = true
end

local function FinishUltimate(player, standEntity)
	local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"]

    standItemData.UltimateCooldown = STATS.UltimateCooldown
end

local function UpdateUltimate(player, standEntity)
    local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"]

	if standItemData.UltimateCooldown and stand.UltimateCooldown > 0 then
        standItemData.UltimateCooldown = math.max(0, stand.UltimateCooldown - 1)
    end

    if standItemData.UltimateDuration and standItemData.UltimateDuration > 0 then
        standItemData.UltimateDuration = math.max(0, standItemData.UltimateDuration - 1)
        if standItemData.UltimateDuration == 0 then 
            FinishUltimate(player, stand)
        end
    end
end

---@param player EntityPlayer
return function (player, standEntity)
    
    local playerData = player:GetData()
    if player:HasCollectible(standItem) then

        local controler = player.ControllerIndex
        local standItemData = playerData[stand.Id..".Item"]
        
        if Input.IsButtonPressed(SETTINGS.KEY_ULTIMATE, controler) 
        or (SETTINGS.ControllerOn and Input.IsActionTriggered(ButtonAction.ACTION_DROP, controler))
        then
            if standItemData.UltimateCharge == STATS.UltimateMaxCharge then
                DoUltimate(player, stand)
            end
        end

        UpdateUltimate(player, stand)
    end
end