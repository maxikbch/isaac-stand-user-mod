local STAND_ID = "hierophant_green"
local SKILL_ID = "emerald_splash"

local function getSkillDef(standDef)
    return standDef.skills and standDef.skills[SKILL_ID]
end

local function getPoolCharge(standState, standDef)
    local poolId = "primary"
    local skillDef = getSkillDef(standDef)
    if skillDef and skillDef.chargePool then
        poolId = skillDef.chargePool
    end
    local charges = standState.charges or {}
    return charges[poolId] or 0, poolId
end

local function setPoolCharge(standState, poolId, value)
    standState.charges = standState.charges or {}
    standState.charges[poolId] = value
end

local function getCooldown(standState)
    local cooldowns = standState.skillCooldowns or {}
    return cooldowns[SKILL_ID] or 0
end

local function setCooldown(standState, value)
    standState.skillCooldowns = standState.skillCooldowns or {}
    standState.skillCooldowns[SKILL_ID] = value
end

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
    local standState = ctx.standState

    if standDef.id ~= STAND_ID then
        return false
    end

    local skillDef = getSkillDef(standDef)
    if not skillDef then
        return false
    end

    if getCooldown(standState) > 0 then
        return false
    end

    local charge, poolId = getPoolCharge(standState, standDef)
    local useCost = skillDef.useCost or standDef.stats.SuperMaxCharge
    if charge < useCost then
        return false
    end

    local playerData = player:GetData()
    if playerData.shoot then
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

    setPoolCharge(standState, poolId, charge - useCost)

    standData.superRush = true
    standData.launchdir = normalizeDir(playerData.releasedir, player)
    standData.launchto = standData.tgt.Position
    standData.behavior = "rush"

    return true
end

function emeraldSplash.onSuperComplete(player, jsf)
    local standDef = jsf:GetStand(STAND_ID)
    local jsfData = jsf:GetPlayerData(player)
    local standState = jsfData and jsfData.standState
    if standDef and standState then
        setCooldown(standState, standDef.stats.SuperCooldown)
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

function emeraldSplash.postUpdate(JSF)
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player and player:Exists() then
            local standDef = JSF:GetActiveStand(player)
            if standDef and standDef.id == STAND_ID then
                local jsfData = JSF:GetPlayerData(player)
                local standState = jsfData and jsfData.standState
                if standState then
                    local cooldown = getCooldown(standState)
                    if cooldown > 0 then
                        setCooldown(standState, cooldown - 1)
                    end
                end
            end
        end
    end
end

return emeraldSplash
