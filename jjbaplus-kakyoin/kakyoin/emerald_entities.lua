local game = Game()

local TEAR_SUBTYPE = 0
local EMERALD_NAME = "HG Emerald"
local RADIO_NAME = "HG Emerald Radio"
--- Base art (`emeralds.anm2`) points toward North (screen up); Isaac 0° is East.
local SPRITE_ANGLE_OFFSET = 90

local variants = {
    emerald = -1,
    radio = -1,
}
local initialized = false

local function ensureVariants()
    if initialized then
        return
    end
    initialized = true

    variants.emerald = Isaac.GetEntityVariantByName(EMERALD_NAME)
    variants.radio = Isaac.GetEntityVariantByName(RADIO_NAME)

    if variants.emerald < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] missing entity variant: " .. EMERALD_NAME)
    end
    if variants.radio < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] missing entity variant: " .. RADIO_NAME)
    end
end

local function vecFromAngle(angle, speed)
    return Vector.FromAngle(angle) * speed
end

local function applySpriteRotation(tear)
    local sprite = tear:GetSprite()
    sprite.Rotation = tear.Velocity:GetAngleDegrees() + SPRITE_ANGLE_OFFSET
end

local function spawnEmeraldTear(player, position, velocity, damageMult, stats)
    ensureVariants()

    local variant = variants.emerald
    if not variant or variant < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] fallback tear variant for emerald")
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
    applySpriteRotation(tear)
    tear:GetData().jjbaEmerald = true

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

local function onTearUpdate(tear)
    if tear:GetData().jjbaEmerald then
        applySpriteRotation(tear)
    end
end

return {
    vecFromAngle = vecFromAngle,
    spawnTear = spawnEmeraldTear,
    spawnRadioEffect = spawnRadioEffect,
    onTearUpdate = onTearUpdate,
    init = ensureVariants,
}
