
local stand = require("src/constants/stand")
local STATS = require("src/constants/stats")
local SETTINGS = require("src/constants/settings")
local standItem = require("src/stand/item")

local function DoSuper(player, standEntity)
    local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"]

    --stand.room2 = Game():GetLevel():GetCurrentRoomIndex()
    standItemData.SuperDuration = STATS.SuperDuration
    --sfx:Play(snd.STOP_TIME,2,0,false,1)
    --sfx:Play(snd.STZW,2,0,false,1)
    --stand.savedTime = game.TimeCounter
    --music:Disable()
    --StandIsCharged = false
    standItemData.SuperCharge = 0
    --stand.StandActive = true
end

local function FinishSuper(player, standEntity)
	local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"]

    standItemData.SuperCooldown = STATS.SuperCooldown
end

local function UpdateSuper(player, standEntity)
    local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"] or {}

	if (standItemData.SuperCooldown or 0) > 0 then
        standItemData.SuperCooldown = math.max(0, standItemData.SuperCooldown - 1)
    end

    if (standItemData.SuperDuration or 0) > 0 then
        standItemData.SuperDuration = math.max(0, standItemData.SuperDuration - 1)
        if standItemData.SuperDuration == 0 then 
            FinishSuper(player, stand)
        end
    end
end

---@param player EntityPlayer
return function (player, standEntity)
    
    local playerData = player:GetData()
    if player:HasCollectible(standItem) then

        local controler = player.ControllerIndex
        local standItemData = playerData[stand.Id..".Item"] or {}
        
        if Input.IsButtonPressed(SETTINGS.KEY_SUPER, controler) or Input.IsButtonPressed(10, controler)
        or (SETTINGS.ControllerOn and Input.IsActionTriggered(ButtonAction.ACTION_DROP, controler))
        then
            if standItemData.SuperCharge == STATS.SuperMaxCharge then
                DoSuper(player, stand)
            end
        end

        UpdateSuper(player, stand)
    end
end