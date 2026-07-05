local defaultStats = require("src/constants/default_stats")
local utils = require("src/utils")
local debug = require("src/debug")

local REQUIRED_FIELDS = { "id", "discItem", "familiarVariant" }

local function normalizeAbilities(def)
    local stats = def.stats
    local abilities = def.abilities or {}

    abilities.charges = abilities.charges or {}
    if abilities.charges.super == nil then
        abilities.charges.super = (stats.SuperMaxCharge or 0) > 0
    end
    if abilities.charges.alt == nil then
        abilities.charges.alt = false
    end

    abilities.super = abilities.super or {}
    if abilities.super.enabled == nil then
        abilities.super.enabled = abilities.charges.super
    end
    if abilities.super.requiresCharge == nil then
        abilities.super.requiresCharge = true
    end
    if abilities.super.chargePool == nil then
        abilities.super.chargePool = "super"
    end
    if abilities.super.useCost == nil then
        abilities.super.useCost = stats.SuperMaxCharge
    end

    abilities.alt = abilities.alt or {}
    if abilities.alt.enabled == nil then
        abilities.alt.enabled = false
    end
    if abilities.alt.requiresCharge == nil then
        abilities.alt.requiresCharge = true
    end
    if abilities.alt.chargePool == nil then
        abilities.alt.chargePool = "alt"
    end
    if abilities.alt.useCost == nil then
        abilities.alt.useCost = stats.AltMaxCharge or stats.PowerCost
    end

    def.abilities = abilities
end

local function validateStandDef(def)
    for _, field in ipairs(REQUIRED_FIELDS) do
        if def[field] == nil then
            error("[JoJoStandFramework] RegisterStand missing required field: " .. field)
        end
    end

    if def.discItem == CollectibleType.COLLECTIBLE_NULL or def.discItem == -1 then
        error("[JoJoStandFramework] RegisterStand invalid discItem for stand: " .. tostring(def.id))
    end

    if def.familiarVariant <= 0 then
        error("[JoJoStandFramework] RegisterStand invalid familiarVariant for stand: " .. tostring(def.id))
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

    def.particleVariant = def.particleVariant or (def.familiarVariant + 1)
    def.floatOffset = def.floatOffset or Vector(0, -36)
    def.meterGfx = def.meterGfx or {}

    normalizeAbilities(def)
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

        debug:Log(string.format(
            "RegisterStand ok id=%s disc=%s variant=%s linkedChars=%d",
            def.id,
            tostring(def.discItem),
            tostring(def.familiarVariant),
            #def.linkedCharacters
        ))
    end
end
