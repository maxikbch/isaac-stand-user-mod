local SkillState = require("src/skills/state")

local STAND_ID = "hierophant_green"
local SKILL_ID = "emerald_splash"

local function normalizeDir(dir, player)
    if dir and dir:Length() > 0 then
        return dir
    end
    return Vector.FromAngle(player:GetHeadDirection() * 90)
end

local emeraldSplash = {}

function emeraldSplash.tryActivate(ctx)
    local player = ctx.player
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

    if not standData.tgt then
        return false
    end

    standData.superRush = true
    standData.launchdir = normalizeDir(input.releasedir, player)
    standData.launchto = standData.tgt.Position
    standData.behavior = "rush"

    return true
end

function emeraldSplash.onSuperComplete(player, jsfPlayerData)
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
    standData.radioEntity = nil
    standData.radioOrigin = nil
    standData.radioFrames = nil
    standData.superRush = false
end

return emeraldSplash
