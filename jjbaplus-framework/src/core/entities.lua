local entityIds = require("src/constants/entity_ids")

local Entities = {}

function Entities.ResolveVariant(modTag, modVariant)
    return modTag * 100 + modVariant
end

function Entities.ValidateModTag(modTag)
    if modTag < 0 or modTag > entityIds.MAX_MOD_TAG then
        error("[JoJoStandFramework] modTag out of range (0.." .. entityIds.MAX_MOD_TAG .. "): " .. tostring(modTag))
    end
end

function Entities.ValidateModVariant(modVariant)
    if modVariant < 0 or modVariant > entityIds.MAX_MOD_VARIANT then
        error("[JoJoStandFramework] modVariant out of range (0.." .. entityIds.MAX_MOD_VARIANT .. "): " .. tostring(modVariant))
    end
end

function Entities.ResolveSubtype(standIndex)
    if standIndex == entityIds.DEBUG_STAND_INDEX then
        return entityIds.MAX_STAND_INDEX
    end
    if standIndex < 0 or standIndex > entityIds.MAX_PLAYABLE_STAND_INDEX then
        error("[JoJoStandFramework] standIndex out of range (-1 or 0.."
            .. entityIds.MAX_PLAYABLE_STAND_INDEX .. "): " .. tostring(standIndex))
    end
    return standIndex
end

function Entities.ValidateStandIndex(standIndex)
    Entities.ResolveSubtype(standIndex)
end

function Entities.ResolveEntity(modTag, standIndex, entityDef)
    local variant = Entities.ResolveVariant(modTag, entityDef.modVariant)
    if variant > entityIds.MAX_VARIANT then
        error("[JoJoStandFramework] resolved variant exceeds " .. entityIds.MAX_VARIANT .. ": " .. tostring(variant))
    end

    local resolved = {
        name = entityDef.name,
        type = entityDef.type,
        modVariant = entityDef.modVariant,
        variant = variant,
        subtype = Entities.ResolveSubtype(standIndex),
    }

    if entityDef.name then
        local typeByName = Isaac.GetEntityTypeByName(entityDef.name)
        local variantByName = Isaac.GetEntityVariantByName(entityDef.name)
        if typeByName and typeByName > 0 then
            resolved.type = typeByName
        end
        if variantByName and variantByName >= 0 then
            resolved.variant = variantByName
        end
    end

    return resolved
end

function Entities.Get(standDef, kind)
    return standDef.entities and standDef.entities[kind]
end

function Entities.Matches(standDef, kind, entity)
    local entityDef = Entities.Get(standDef, kind)
    if not entityDef or not entity then
        return false
    end
    return entity.Variant == entityDef.variant and entity.SubType == entityDef.subtype
end

function Entities.MatchesKind(standDef, kind, entity, requireType)
    if not Entities.Matches(standDef, kind, entity) then
        return false
    end
    if requireType then
        local entityDef = Entities.Get(standDef, kind)
        return entity.Type == entityDef.type
    end
    return true
end

function Entities.Spawn(standDef, kind, position, velocity, spawner)
    local entityDef = Entities.Get(standDef, kind)
    if not entityDef then
        error("[JoJoStandFramework] unknown entity kind: " .. tostring(kind))
    end
    return Isaac.Spawn(
        entityDef.type,
        entityDef.variant,
        entityDef.subtype,
        position,
        velocity or Vector(0, 0),
        spawner
    )
end

return Entities
