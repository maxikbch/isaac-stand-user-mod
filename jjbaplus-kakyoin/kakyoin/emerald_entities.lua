local game = Game()

local TEAR_SUBTYPE = 0

local VARIANT_NAMES = {
    ns = "HG Emerald NS",
    ew = "HG Emerald EW",
    d1 = "HG Emerald D1",
    d2 = "HG Emerald D2",
    radio = "HG Emerald Radio",
}

local variants = {}
local initialized = false

local function ensureVariants()
    if initialized then
        return
    end
    initialized = true

    for key, name in pairs(VARIANT_NAMES) do
        local variant = Isaac.GetEntityVariantByName(name)
        variants[key] = variant
        if variant < 0 then
            Isaac.DebugString("[JJBA+ Kakyoin] missing entity variant: " .. name)
        end
    end
end

local function vecFromAngle(angle, speed)
    return Vector.FromAngle(angle) * speed
end

local function spawnEmeraldTear(player, position, velocity, damageMult, stats, kind)
    ensureVariants()

    local variant = variants[kind or "ns"]
    if not variant or variant < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] fallback tear variant for kind: " .. tostring(kind))
        variant = 0
    end

    local spawnPos = game:GetRoom():GetClampedPosition(position, 20)
    local entity = Isaac.Spawn(EntityType.ENTITY_TEAR, variant, TEAR_SUBTYPE, spawnPos, velocity, nil)
    if not entity or not entity:Exists() then
        return nil
    end

    local tear = entity:ToTear()
    tear.CollisionDamage = player.Damage * damageMult * stats.Damage
    tear.Scale = stats.PunchSize
    tear.Height = -8

    return entity
end

local function spawnRadioEffect(position)
    ensureVariants()

    local variant = variants.radio
    if not variant or variant < 0 then
        return Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.NULL, 0, position, Vector(0, 0), nil)
    end

    return Isaac.Spawn(EntityType.ENTITY_EFFECT, variant, TEAR_SUBTYPE, position, Vector(0, 0), nil)
end

return {
    vecFromAngle = vecFromAngle,
    spawnTear = spawnEmeraldTear,
    spawnRadioEffect = spawnRadioEffect,
    init = ensureVariants,
}
