local defaultStats = require("src/constants/default_stats")
local utils = require("src/utils")

local REQUIRED_FIELDS = { "id", "discItem", "familiarVariant" }

local function validateStandDef(def)
    for _, field in ipairs(REQUIRED_FIELDS) do
        if def[field] == nil then
            error("[JoJoStandFramework] RegisterStand missing required field: " .. field)
        end
    end

    if def.discItem == CollectibleType.COLLECTIBLE_NULL or def.discItem == -1 then
        error("[JoJoStandFramework] RegisterStand invalid discItem for stand: " .. tostring(def.id))
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
    end
end
