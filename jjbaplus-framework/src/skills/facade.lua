local SkillState = require("src/skills/state")

local function getStandState(player, jsf)
    jsf = jsf or _G.JoJoStandFramework
    if not jsf then
        return nil
    end
    local jsfData = jsf:GetPlayerData(player)
    return jsfData and jsfData.standState
end

local function getDuration(player, skillId, jsf)
    local standState = getStandState(player, jsf)
    if not standState then
        return 0
    end
    return SkillState.getDuration(standState, skillId)
end

local function setDuration(player, skillId, value, jsf)
    local standState = getStandState(player, jsf)
    if not standState then
        return
    end
    SkillState.setDuration(standState, skillId, value)
end

local function getCooldown(player, skillId, jsf)
    local standState = getStandState(player, jsf)
    if not standState then
        return 0
    end
    return SkillState.getCooldown(standState, skillId)
end

local function setCooldown(player, skillId, value, jsf)
    local standState = getStandState(player, jsf)
    if not standState then
        return
    end
    SkillState.setCooldown(standState, skillId, value)
end

local function getCharge(player, poolId, jsf)
    local standState = getStandState(player, jsf)
    if not standState then
        return 0
    end
    return SkillState.getCharge(standState, poolId or "primary")
end

local function setCharge(player, poolId, value, jsf)
    local standState = getStandState(player, jsf)
    if not standState then
        return
    end
    SkillState.setCharge(standState, poolId or "primary", value)
end

return {
    getDuration = getDuration,
    setDuration = setDuration,
    getCooldown = getCooldown,
    setCooldown = setCooldown,
    getCharge = getCharge,
    setCharge = setCharge,
}
