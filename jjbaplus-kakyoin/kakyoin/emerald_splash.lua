local SkillState = require("src/skills/state")
local settings = require("kakyoin.settings")
local radioNet = require("kakyoin.radio_net")

local STAND_ID = "hierophant_green"
local SKILL_ID = "emerald_splash"

local emeraldSplash = {}

function emeraldSplash.tryActivate(ctx)
    local standDef = ctx.standDef
    local jsf = ctx.jsf
    local input = jsf.input or {}

    if standDef.id ~= STAND_ID then
        return false
    end

    if input.shoot then
        return false
    end

    local standEntity = jsf.standEntity
    if not standEntity or not standEntity:Exists() then
        return false
    end

    local standData = standEntity:GetData()
    if standData.behavior ~= "idle" then
        return false
    end

    local s = standDef.stats
    standData.behavior = "radio"
    standData.radioFrames = (s.RadioKuraeFrames or 23) + (s.RadioLayoutFrames or 51) + (s.RadioRainFrames or s.RadioBurstFrames or 76)
    standData.radioMaxFrames = standData.radioFrames
    standData.radioPhase = nil

    return true
end

function emeraldSplash.onSuperComplete(player, jsfPlayerData)
    if settings.FreeSkill1 then
        return
    end

    local framework = _G.JoJoStandFramework
    if not framework then
        return
    end

    local standDef = framework:GetStand(STAND_ID)
    local standState = jsfPlayerData and jsfPlayerData.standState
    if standDef and standState then
        SkillState.setCooldown(standState, SKILL_ID, standDef.stats.SuperCooldown)
    end
end

function emeraldSplash.cleanupStandState(standEntity)
    if not standEntity or not standEntity:Exists() then
        return
    end

    local standData = standEntity:GetData()
    if standData.radioEntity and standData.radioEntity:Exists() then
        standData.radioEntity:Remove()
    end
    if standData.radioTrails then
        for _, entity in ipairs(standData.radioTrails) do
            if entity and entity:Exists() then
                entity:Remove()
            end
        end
    end
    if standData.radioEdgeTrails then
        for _, entity in ipairs(standData.radioEdgeTrails) do
            if entity and entity:Exists() then
                entity:Remove()
            end
        end
    end
    if standData.radioWeavers then
        for _, weaver in ipairs(standData.radioWeavers) do
            if weaver.entity and weaver.entity:Exists() then
                weaver.entity:Remove()
            end
        end
    end
    if standData.radioRainMuzzles then
        for _, entity in ipairs(standData.radioRainMuzzles) do
            if entity and entity:Exists() then
                entity:Remove()
            end
        end
    end
    radioNet.destroy(standData)
    standData.radioEntity = nil
    standData.radioOrigin = nil
    standData.radioFrames = nil
    standData.radioMaxFrames = nil
    standData.radioPhase = nil
    standData.radioTrails = nil
    standData.radioEdgeTrails = nil
    standData.radioWeavers = nil
    standData.radioRainMuzzles = nil
    standData.radioWeaveQueue = nil
    standData.radioWeaveCooldown = nil
    standData.radioWeaveElapsed = nil
    standData.radioRainSection = nil
    standData.superRush = false
end

return emeraldSplash
