
local stand = require("src/constants/stand")
local STATS = require("src/constants/stats")
local Settings = require("src/constants/settings")
local standItem = require("src/stand/item")

local function DoSuper(player, standEntity)
    local playerData = player:GetData()
    local standItemData = playerData[stand.Id..".Item"]

    standItemData.SuperDuration = STATS.SuperDuration
    standItemData.SuperCharge = 0
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
        
        if Input.IsButtonPressed(Settings.KEY_PRIMARY, controler) or Input.IsButtonPressed(Settings.BUTTON_PRIMARY, controler)
        then
            if standItemData.SuperCharge == STATS.SuperMaxCharge then
                DoSuper(player, stand)
            end
        end

        UpdateSuper(player, stand)
    end
end