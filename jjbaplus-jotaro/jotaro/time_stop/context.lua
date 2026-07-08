local STAND_ID = "star_platinum"
local SKILL_ID = "time_stop"

local function getSkillDuration(player, JSF)
    return JSF.Skills.getDuration(player, SKILL_ID, JSF)
end

local function setSkillDuration(player, value, JSF)
    JSF.Skills.setDuration(player, SKILL_ID, value, JSF)
end

local function getStandContext(player, JSF)
    local standDef = JSF:GetActiveStand(player)
    if not standDef or standDef.id ~= STAND_ID then
        return nil, nil
    end

    if not player:HasCollectible(standDef.discItem) then
        return nil, nil
    end

    local jsfData = JSF:GetPlayerData(player)
    return standDef, jsfData.standState
end

local function forEachStarPlatinumPlayer(JSF, fn)
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player and player:Exists() then
            local standDef, standState = getStandContext(player, JSF)
            if standDef and standState then
                fn(player, standDef, standState)
            end
        end
    end
end

return {
    STAND_ID = STAND_ID,
    SKILL_ID = SKILL_ID,
    getSkillDuration = getSkillDuration,
    setSkillDuration = setSkillDuration,
    getStandContext = getStandContext,
    forEachStarPlatinumPlayer = forEachStarPlatinumPlayer,
}
