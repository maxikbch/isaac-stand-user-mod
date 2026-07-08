local StandInput = require("src/core/input")
local SkillState = require("src/skills/state")
local SkillResolve = require("src/skills/resolve")
local utils = require("src/utils")

local SLOT_BINDINGS = {
    skill1 = function(index) return StandInput:IsSkill1Triggered(index) end,
    skill2 = function(index) return StandInput:IsSkill2Triggered(index) end,
}

local function makeContext(player, standDef, jsf, slotName, skillId)
    return {
        player = player,
        standDef = standDef,
        standEntity = jsf.standEntity,
        standState = jsf.standState,
        jsf = jsf,
        slot = slotName,
        skillId = skillId,
    }
end

local function getPoolDef(standDef, poolId)
    return standDef.chargePools and standDef.chargePools[poolId]
end

local function canPayCost(standState, skillDef, standDef)
    local poolId = skillDef.chargePool or "primary"
    local poolDef = getPoolDef(standDef, poolId)
    if not poolDef then
        return true
    end

    local useCost = skillDef.useCost
    if useCost == nil then
        useCost = poolDef.maxCharge or 0
    end

    if useCost <= 0 then
        return true
    end

    return SkillState.getCharge(standState, poolId) >= useCost
end

local function payCost(standState, skillDef, standDef)
    local poolId = skillDef.chargePool or "primary"
    local poolDef = getPoolDef(standDef, poolId)
    if not poolDef then
        return
    end

    local useCost = skillDef.useCost
    if useCost == nil then
        useCost = poolDef.maxCharge or 0
    end

    if useCost <= 0 then
        return
    end

    SkillState.setCharge(standState, poolId, SkillState.getCharge(standState, poolId) - useCost)
end

local function activateActive(player, standDef, jsf, slotName, skillId, skillDef, ctx)
    local standState = jsf.standState
    local duration = skillDef.duration or 0

    if duration > 0 then
        SkillState.setDuration(standState, skillId, duration)
    end

    payCost(standState, skillDef, standDef)

    if skillDef.onActivate then
        skillDef.onActivate(ctx)
    end
end

local function deactivateActive(player, standDef, jsf, skillId, skillDef, ctx)
    local standState = jsf.standState
    local cooldown = skillDef.cooldown or 0

    SkillState.setDuration(standState, skillId, 0)

    if cooldown > 0 then
        SkillState.setCooldown(standState, skillId, cooldown)
    end

    if skillDef.onDeactivate then
        skillDef.onDeactivate(ctx)
    end
end

local function tryInstant(player, standDef, jsf, slotName, skillId, skillDef, ctx)
    local standState = jsf.standState
    local slotDef = standDef.slots[slotName]
    local requiresCharge = slotDef.requiresCharge ~= false

    if requiresCharge and not canPayCost(standState, skillDef, standDef) then
        return
    end

    if SkillState.getCooldown(standState, skillId) > 0 then
        return
    end

    payCost(standState, skillDef, standDef)

    local cooldown = skillDef.cooldown or 0
    if cooldown > 0 then
        SkillState.setCooldown(standState, skillId, cooldown)
    end

    if skillDef.onActivate then
        skillDef.onActivate(ctx)
    elseif skillDef.onPress then
        skillDef.onPress(ctx)
    end
end

local function tryToggle(player, standDef, jsf, slotName, skillId, skillDef, ctx)
    local standState = jsf.standState
    local nextOn = not SkillState.isToggleOn(standState, skillId)
    SkillState.setToggle(standState, skillId, nextOn)

    if nextOn then
        if skillDef.onActivate then
            skillDef.onActivate(ctx)
        end
    elseif skillDef.onDeactivate then
        skillDef.onDeactivate(ctx)
    end

    if skillDef.onToggle then
        skillDef.onToggle(ctx, nextOn)
    end
end

local function tryCustom(player, standDef, jsf, slotName, skillId, skillDef, ctx, requiresCharge)
    local standState = jsf.standState

    if requiresCharge and not canPayCost(standState, skillDef, standDef) then
        return
    end

    local activated = false
    if skillDef.onPress then
        activated = skillDef.onPress(ctx) == true
    end

    if not activated then
        return
    end

    payCost(standState, skillDef, standDef)

    local cooldown = skillDef.cooldown or 0
    if cooldown > 0 and skillDef.cooldownStartsOn ~= "complete" then
        SkillState.setCooldown(standState, skillId, cooldown)
    end
end

local function tryActivateSlot(slotName, player, standDef, jsf)
    local slotDef = standDef.slots and standDef.slots[slotName]
    if not slotDef or not slotDef.enabled then
        return
    end

    local standState = jsf.standState
    local skillId = SkillResolve.resolveSkillId(slotDef, player, standDef, standState)
    if not skillId then
        return
    end

    local skillDef = standDef.skills and standDef.skills[skillId]
    if not skillDef then
        return
    end

    local ctx = makeContext(player, standDef, jsf, slotName, skillId)
    local kind = skillDef.kind or "instant"
    local requiresCharge = slotDef.requiresCharge
    if requiresCharge == nil then
        requiresCharge = kind == "active"
    end

    if SkillState.getCooldown(standState, skillId) > 0 then
        return
    end

    if kind == "active" then
        if SkillState.getDuration(standState, skillId) > 0 then
            return
        end
        if requiresCharge and not canPayCost(standState, skillDef, standDef) then
            return
        end
        activateActive(player, standDef, jsf, slotName, skillId, skillDef, ctx)
        return
    end

    if kind == "toggle" then
        tryToggle(player, standDef, jsf, slotName, skillId, skillDef, ctx)
        return
    end

    if kind == "custom" then
        tryCustom(player, standDef, jsf, slotName, skillId, skillDef, ctx, requiresCharge)
        return
    end

    -- instant (default)
    tryInstant(player, standDef, jsf, slotName, skillId, skillDef, ctx)
end

local function tickSkills(player, standDef, jsf)
    local standState = jsf.standState
    if not standState or not standDef.skills then
        return
    end

    for skillId, skillDef in pairs(standDef.skills) do
        local cooldown = SkillState.getCooldown(standState, skillId)
        if cooldown > 0 then
            SkillState.setCooldown(standState, skillId, cooldown - 1)
        end

        if skillDef.kind ~= "active" then
            -- skip non-active skills
        else
            local duration = SkillState.getDuration(standState, skillId)
            if duration > 0 then
                duration = duration - 1
                SkillState.setDuration(standState, skillId, duration)

                if skillDef.onTick then
                    skillDef.onTick(makeContext(player, standDef, jsf, nil, skillId))
                end

                if duration == 0 then
                    deactivateActive(
                        player,
                        standDef,
                        jsf,
                        skillId,
                        skillDef,
                        makeContext(player, standDef, jsf, nil, skillId)
                    )
                end
            end
        end
    end
end

return function(player, standDef, jsf)
    if not player:HasCollectible(standDef.discItem) then
        return
    end

    jsf.standState = jsf.standState or {}
    SkillState.ensurePools(jsf.standState, standDef.chargePools)

    if not Game():IsPaused() and utils:IsLocallyControlledPlayer(player) then
        local controllerIndex = player.ControllerIndex

        for slotName, isTriggered in pairs(SLOT_BINDINGS) do
            if isTriggered(controllerIndex) then
                tryActivateSlot(slotName, player, standDef, jsf)
            end
        end
    end

    tickSkills(player, standDef, jsf)
end
