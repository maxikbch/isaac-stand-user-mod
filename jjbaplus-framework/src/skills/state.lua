local function ensureTable(parent, key)
    if not parent[key] then
        parent[key] = {}
    end
    return parent[key]
end

local function ensurePools(standState, chargePools)
    local charges = ensureTable(standState, "charges")
    for poolId in pairs(chargePools or {}) do
        if charges[poolId] == nil then
            charges[poolId] = 0
        end
    end
end

local function getCharge(standState, poolId)
    local charges = standState and standState.charges
    if not charges then
        return 0
    end
    return charges[poolId] or 0
end

local function setCharge(standState, poolId, value)
    standState.charges = ensureTable(standState, "charges")
    standState.charges[poolId] = value
end

local function addCharge(standState, poolId, amount, maxCharge)
    local current = getCharge(standState, poolId)
    if current >= maxCharge then
        return current
    end
    local nextCharge = math.min(maxCharge, current + amount)
    setCharge(standState, poolId, nextCharge)
    return nextCharge
end

local function getDuration(standState, skillId)
    local durations = standState and standState.skillDurations
    if not durations then
        return 0
    end
    return durations[skillId] or 0
end

local function setDuration(standState, skillId, value)
    standState.skillDurations = ensureTable(standState, "skillDurations")
    standState.skillDurations[skillId] = value
end

local function getCooldown(standState, skillId)
    local cooldowns = standState and standState.skillCooldowns
    if not cooldowns then
        return 0
    end
    return cooldowns[skillId] or 0
end

local function setCooldown(standState, skillId, value)
    standState.skillCooldowns = ensureTable(standState, "skillCooldowns")
    standState.skillCooldowns[skillId] = value
end

local function isToggleOn(standState, skillId)
    local toggles = standState and standState.toggles
    if not toggles then
        return false
    end
    return toggles[skillId] == true
end

local function setToggle(standState, skillId, on)
    standState.toggles = ensureTable(standState, "toggles")
    standState.toggles[skillId] = on
end

local function hasAnyActiveDuration(standState)
    if not standState or not standState.skillDurations then
        return false
    end
    for _, duration in pairs(standState.skillDurations) do
        if (duration or 0) > 0 then
            return true
        end
    end
    return false
end

return {
    ensurePools = ensurePools,
    getCharge = getCharge,
    setCharge = setCharge,
    addCharge = addCharge,
    getDuration = getDuration,
    setDuration = setDuration,
    getCooldown = getCooldown,
    setCooldown = setCooldown,
    isToggleOn = isToggleOn,
    setToggle = setToggle,
    hasAnyActiveDuration = hasAnyActiveDuration,
}
