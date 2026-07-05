local Settings = require("src/constants/settings")

local function DoSuper(player, standDef, jsf)
    local standState = jsf.standState
    local STATS = standDef.stats

    standState.SuperDuration = STATS.SuperDuration
    standState.SuperCharge = 0

    if standDef.hooks.onSuperStart then
        standDef.hooks.onSuperStart(player, jsf.standEntity, standDef)
    end
end

local function FinishSuper(player, standDef, jsf)
    local standState = jsf.standState
    local STATS = standDef.stats

    standState.SuperCooldown = STATS.SuperCooldown

    if standDef.hooks.onSuperFinish then
        standDef.hooks.onSuperFinish(player, jsf.standEntity, standDef)
    end
end

local function UpdateSuper(player, standDef, jsf)
    local standState = jsf.standState or {}
    local STATS = standDef.stats

    if (standState.SuperCooldown or 0) > 0 then
        standState.SuperCooldown = math.max(0, standState.SuperCooldown - 1)
    end

    if (standState.SuperDuration or 0) > 0 then
        standState.SuperDuration = math.max(0, standState.SuperDuration - 1)
        if standState.SuperDuration == 0 then
            FinishSuper(player, standDef, jsf)
        end
    end
end

return function(player, standDef, jsf)
    if not player:HasCollectible(standDef.discItem) then
        return
    end

    local controler = player.ControllerIndex
    local standState = jsf.standState or {}
    local STATS = standDef.stats

    if Input.IsButtonPressed(Settings.KEY_PRIMARY, controler) or Input.IsButtonPressed(Settings.BUTTON_PRIMARY, controler) then
        if standState.SuperCharge == STATS.SuperMaxCharge then
            DoSuper(player, standDef, jsf)
        end
    end

    UpdateSuper(player, standDef, jsf)
end
