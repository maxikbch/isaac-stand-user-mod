local defaultStats = require("src/constants/default_stats")
local entityIds = require("src/constants/entity_ids")
local entities = require("src/core/entities")
local utils = require("src/utils")
local debug = require("src/debug")

local REQUIRED_FIELDS = { "id", "discItem", "standIndex", "entities" }
local REQUIRED_ENTITY_KINDS = { entityIds.KIND_STAND, entityIds.KIND_PARTICLE }

local SLOT_NAMES = { "skill1", "skill2" }

local function mergeSkillHooks(def, skillId, skill)
    local hooks = def.hooks or {}

    if skill.onActivate == nil and hooks.onSkillActivate then
        skill.onActivate = hooks.onSkillActivate[skillId]
    end
    if skill.onDeactivate == nil and hooks.onSkillDeactivate then
        skill.onDeactivate = hooks.onSkillDeactivate[skillId]
    end
    if skill.onPress == nil and hooks.onSkillPress then
        skill.onPress = hooks.onSkillPress[skillId]
    end
    if skill.onToggle == nil and hooks.onSkillToggle then
        skill.onToggle = hooks.onSkillToggle[skillId]
    end
    if skill.onTick == nil and hooks.onSkillTick then
        skill.onTick = hooks.onSkillTick[skillId]
    end
end

local function normalizeChargePools(def)
    local stats = def.stats
    def.chargePools = def.chargePools or {}

    if not next(def.chargePools) and (stats.SuperMaxCharge or 0) > 0 then
        def.chargePools.primary = {
            maxCharge = stats.SuperMaxCharge,
            gainOnHit = true,
        }
    end

    for poolId, poolDef in pairs(def.chargePools) do
        if poolDef.maxCharge == nil then
            if poolId == "primary" then
                poolDef.maxCharge = stats.SuperMaxCharge or 0
            elseif poolId == "secondary" then
                poolDef.maxCharge = stats.AltMaxCharge or stats.PowerCost or 0
            else
                poolDef.maxCharge = 0
            end
        end
        if poolDef.gainOnHit == nil then
            poolDef.gainOnHit = poolId == "primary"
        end
    end
end

local function normalizeSlots(def)
    def.slots = def.slots or {}

    for _, slotName in ipairs(SLOT_NAMES) do
        local slot = def.slots[slotName] or { enabled = false }
        def.slots[slotName] = slot

        if slot.enabled == nil then
            slot.enabled = false
        end
        if slot.chargePool == nil then
            slot.chargePool = slotName == "skill1" and "primary" or "secondary"
        end
        if slot.requiresCharge == nil then
            slot.requiresCharge = true
        end
    end
end

local function normalizeSkills(def)
    def.skills = def.skills or {}
    local stats = def.stats

    for skillId, skill in pairs(def.skills) do
        if skill.kind == nil then
            skill.kind = "active"
        end
        if skill.chargePool == nil then
            skill.chargePool = "primary"
        end

        local poolDef = def.chargePools[skill.chargePool]
        if skill.useCost == nil and poolDef then
            skill.useCost = poolDef.maxCharge
        end
        if skill.duration == nil and skill.kind == "active" then
            skill.duration = stats.SuperDuration or 0
        end
        if skill.cooldown == nil then
            skill.cooldown = stats.SuperCooldown or 0
        end

        mergeSkillHooks(def, skillId, skill)
    end
end

local function normalizeEntities(def)
    def.modTag = def.modTag or entityIds.DEFAULT_MOD_TAG
    entities.ValidateModTag(def.modTag)
    entities.ValidateStandIndex(def.standIndex)

    for _, kind in ipairs(REQUIRED_ENTITY_KINDS) do
        local defaults = entityIds.DEFAULT_ENTITIES[kind]
        local entityDef = def.entities[kind] or {}
        def.entities[kind] = entityDef

        if entityDef.type == nil then
            entityDef.type = defaults.type
        end
        if entityDef.modVariant == nil then
            entityDef.modVariant = defaults.modVariant
        end

        entities.ValidateModVariant(entityDef.modVariant)

        local resolved = entities.ResolveEntity(def.modTag, def.standIndex, entityDef)
        for key, value in pairs(resolved) do
            entityDef[key] = value
        end
    end

    for kind, entityDef in pairs(def.entities) do
        local isRequired = false
        for _, requiredKind in ipairs(REQUIRED_ENTITY_KINDS) do
            if kind == requiredKind then
                isRequired = true
                break
            end
        end
        if not isRequired and entityDef.modVariant ~= nil and not entityDef.variant then
            entities.ValidateModVariant(entityDef.modVariant)
            local resolved = entities.ResolveEntity(def.modTag, def.standIndex, entityDef)
            for key, value in pairs(resolved) do
                entityDef[key] = value
            end
        end
    end
end

local function validateStandDef(def)
    for _, field in ipairs(REQUIRED_FIELDS) do
        if def[field] == nil then
            error("[JoJoStandFramework] RegisterStand missing required field: " .. field)
        end
    end

    if def.behaviorModule == nil then
        error("[JoJoStandFramework] RegisterStand missing required field: behaviorModule for stand: " .. tostring(def.id))
    end

    if def.discItem == CollectibleType.COLLECTIBLE_NULL or def.discItem == -1 then
        error("[JoJoStandFramework] RegisterStand invalid discItem for stand: " .. tostring(def.id))
    end

    for _, kind in ipairs(REQUIRED_ENTITY_KINDS) do
        if def.entities[kind] == nil then
            error("[JoJoStandFramework] RegisterStand missing entities." .. kind .. " for stand: " .. tostring(def.id))
        end
    end
end

local function normalizeStandDef(def)
    def.stats = utils:TableMerge(utils:TableMerge({}, defaultStats), def.stats or {})
    def.hooks = def.hooks or {}
    def.sounds = def.sounds or {}
    def.linkedCharacters = def.linkedCharacters or {}

    if def.animations then
        for key, value in pairs(def.animations) do
            def[key] = value
        end
    end

    def.floatOffset = def.floatOffset or Vector(0, -36)
    def.meterGfx = def.meterGfx or {}

    normalizeEntities(def)
    normalizeChargePools(def)
    normalizeSlots(def)
    normalizeSkills(def)
end

return function(registry)
    return function(def)
        validateStandDef(def)
        normalizeStandDef(def)

        if registry.stands[def.id] then
            error("[JoJoStandFramework] Stand already registered: " .. def.id)
        end

        if registry.discToStand[def.discItem] then
            error("[JoJoStandFramework] discItem already registered: " .. tostring(def.discItem))
        end

        registry.stands[def.id] = def
        registry.discToStand[def.discItem] = def.id

        for _, playerType in ipairs(def.linkedCharacters) do
            registry.characterToStand[playerType] = def.id
        end

        local skillCount = 0
        for _ in pairs(def.skills or {}) do
            skillCount = skillCount + 1
        end

        local standEntity = def.entities[entityIds.KIND_STAND]
        debug:Log(string.format(
            "RegisterStand ok id=%s disc=%s standIndex=%s stand=(%s,%s,%s) linkedChars=%d skills=%d",
            def.id,
            tostring(def.discItem),
            tostring(def.standIndex),
            tostring(standEntity.type),
            tostring(standEntity.variant),
            tostring(standEntity.subtype),
            #def.linkedCharacters,
            skillCount
        ))
    end
end
