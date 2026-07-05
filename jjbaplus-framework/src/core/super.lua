local StandInput = require("src/core/input")

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

local function TryAlt(player, standDef, jsf)
    if standDef.hooks.onAltTriggered then
        standDef.hooks.onAltTriggered(player, jsf.standEntity, standDef)
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

    local controllerIndex = player.ControllerIndex
    local standState = jsf.standState or {}
    local STATS = standDef.stats

    if StandInput:IsSuperTriggered(controllerIndex) then
        if standState.SuperCharge == STATS.SuperMaxCharge then
            DoSuper(player, standDef, jsf)
        end
    end

    if StandInput:IsAltTriggered(controllerIndex) then
        TryAlt(player, standDef, jsf)
    end

    UpdateSuper(player, standDef, jsf)
end
