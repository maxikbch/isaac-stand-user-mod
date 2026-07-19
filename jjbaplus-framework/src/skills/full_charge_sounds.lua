local SkillState = require("src/skills/state")
local SkillResolve = require("src/skills/resolve")
local Audio = require("src/audio")

local DEFAULT_EFFECT = {
    name = "JJBAPlus_FullCharge",
    volume = 1,
}

local SLOT_ORDER = { "skill1", "skill2" }

local function ensureTable(parent, key)
    if not parent[key] then
        parent[key] = {}
    end
    return parent[key]
end

local function getPoolDef(standDef, poolId)
    return standDef.chargePools and standDef.chargePools[poolId]
end

local function getUseCost(slotDef, skillDef, poolDef)
    if slotDef and slotDef.useCost ~= nil then
        return slotDef.useCost
    end
    if skillDef and skillDef.useCost ~= nil then
        return skillDef.useCost
    end
    if poolDef then
        return poolDef.maxCharge or 0
    end
    return 0
end

local function requiresCharge(slotDef, skillDef)
    if slotDef and slotDef.requiresCharge ~= nil then
        return slotDef.requiresCharge
    end
    local kind = skillDef and skillDef.kind or "instant"
    return kind == "active"
end

local function isSkillReady(standState, standDef, slotDef, skillId, skillDef)
    if not requiresCharge(slotDef, skillDef) then
        return false
    end

    local poolId = slotDef.chargePool or skillDef.chargePool or "primary"
    local poolDef = getPoolDef(standDef, poolId)
    local useCost = getUseCost(slotDef, skillDef, poolDef)
    if useCost <= 0 then
        return false
    end

    if SkillState.getCooldown(standState, skillId) > 0 then
        return false
    end

    if SkillState.getDuration(standState, skillId) > 0 then
        return false
    end

    return SkillState.getCharge(standState, poolId) >= useCost
end

local function resolveSoundConfig(skillDef, standDef)
    return (skillDef and skillDef.fullChargeSounds) or (standDef and standDef.fullChargeSounds) or {}
end

--- Detect rising edge of skill readiness and play full-charge cue(s).
local function update(player, standDef, standState)
    if not player or not standDef or not standState then
        return
    end

    local slots = standDef.slots or {}
    local readyState = ensureTable(standState, "skillReady")
    local playedEffects = {}

    for _, slotName in ipairs(SLOT_ORDER) do
        local slotDef = slots[slotName]
        if slotDef and slotDef.enabled then
            local skillId = SkillResolve.resolveSkillId(slotDef, player, standDef, standState)
            local skillDef = skillId and standDef.skills and standDef.skills[skillId]
            if skillId and skillDef then
                local ready = isSkillReady(standState, standDef, slotDef, skillId, skillDef)
                local previous = readyState[skillId]

                -- Seed without playing on first observation (e.g. save restore already full).
                if previous == nil then
                    readyState[skillId] = ready
                elseif ready and previous ~= true then
                    local cfg = resolveSoundConfig(skillDef, standDef)
                    local effect = cfg.effect
                    if effect == nil then
                        effect = DEFAULT_EFFECT
                    elseif effect == false then
                        effect = nil
                    end

                    local effectId = Audio.getId(effect)
                    if effectId and not playedEffects[effectId] then
                        Audio.play(effect)
                        playedEffects[effectId] = true
                    end

                    if cfg.voice then
                        Audio.play(cfg.voice)
                    end

                    readyState[skillId] = ready
                else
                    readyState[skillId] = ready
                end
            end
        end
    end
end

return {
    update = update,
}
