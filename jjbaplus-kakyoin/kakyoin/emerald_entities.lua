local game = Game()
local roomLayout = require("kakyoin.room_layout")

local TEAR_SUBTYPE = 0
local EMERALD_NAME = "HG Emerald"
local RADIO_NAME = "HG Emerald Radio"
local BREAK_NAME = "HG Emerald Break"
local BREAK_ANIM = "Break"
--- Base art (`emeralds.anm2`) points toward North (screen up); Isaac 0° is East.
local SPRITE_ANGLE_OFFSET = 90
--- Tear Height is negative while airborne; near 0 means it has landed.
local LAND_HEIGHT = -5
--- Break is 7 frames at 30fps; keep a little buffer.
local BREAK_TIMEOUT = 12

local variants = {
    emerald = -1,
    radio = -1,
    breakFx = -1,
}
local initialized = false

local function ensureVariants()
    if initialized then
        return
    end
    initialized = true

    variants.emerald = Isaac.GetEntityVariantByName(EMERALD_NAME)
    variants.radio = Isaac.GetEntityVariantByName(RADIO_NAME)
    variants.breakFx = Isaac.GetEntityVariantByName(BREAK_NAME)

    if variants.emerald < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] missing entity variant: " .. EMERALD_NAME)
    end
    if variants.radio < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] missing entity variant: " .. RADIO_NAME)
    end
    if variants.breakFx < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] missing entity variant: " .. BREAK_NAME)
    end
end

local function vecFromAngle(angle, speed)
    return Vector.FromAngle(angle) * speed
end

local function applySpriteRotation(tear)
    local data = tear:GetData()
    local sprite = tear:GetSprite()
    local rotation = tear.Velocity:GetAngleDegrees() + SPRITE_ANGLE_OFFSET
    sprite.Rotation = rotation
    data.breakRotation = rotation
    data.breakScale = tear.Scale
end

local function spawnBreakEffect(position, rotation, scale)
    ensureVariants()

    local variant = variants.breakFx
    if not variant or variant < 0 then
        variant = EffectVariant.NULL
    end

    local entity = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        variant,
        0,
        position,
        Vector.Zero,
        nil
    )
    if not entity or not entity:Exists() then
        return nil
    end

    local effect = entity:ToEffect()
    local sprite = effect:GetSprite()
    sprite:Play(BREAK_ANIM, true)
    sprite.Rotation = rotation or 0
    local s = scale or 1
    sprite.Scale = Vector(s, s)

    effect.DepthOffset = 10
    effect:SetTimeout(BREAK_TIMEOUT)
    effect:GetData().jjbaEmeraldBreak = true
    return effect
end

--- Spawns Break VFX from a tear. When `once` is true, only the first call succeeds.
local function trySpawnBreakFromTear(tear, once)
    local data = tear:GetData()
    if not data.jjbaEmerald then
        return false
    end
    if once and data.breakSpawned then
        return false
    end
    if once then
        data.breakSpawned = true
    end

    local rotation = data.breakRotation
    if rotation == nil then
        local sprite = tear:GetSprite()
        rotation = sprite and sprite.Rotation or 0
    end

    local scale = data.breakScale
    if scale == nil then
        local asTear = tear.ToTear and tear:ToTear()
        scale = (asTear and asTear.Scale) or 1
    end

    spawnBreakEffect(tear.Position, rotation, scale)
    return true
end

--- Native crop size of `emerald_radio.anm2` layer art.
local RADIO_BASE_W = 399
local RADIO_BASE_H = 318

---@param opts { clampSpawn?: boolean, spectral?: boolean, piercing?: boolean, scaleMult?: number }|nil
local function spawnEmeraldTear(player, position, velocity, damageMult, stats, opts)
    ensureVariants()
    opts = opts or {}

    local variant = variants.emerald
    if not variant or variant < 0 then
        Isaac.DebugString("[JJBA+ Kakyoin] fallback tear variant for emerald")
        variant = 0
    end

    local spawnPos = position
    if opts.clampSpawn ~= false then
        spawnPos = game:GetRoom():GetClampedPosition(position, 20)
    end

    local entity = Isaac.Spawn(EntityType.ENTITY_TEAR, variant, TEAR_SUBTYPE, spawnPos, velocity, nil)
    if not entity or not entity:Exists() then
        return nil
    end

    local tear = entity:ToTear()
    tear.CollisionDamage = player.Damage * damageMult * stats.Damage
    tear.Scale = stats.PunchSize * (opts.scaleMult or 1)
    -- Start near ground level; fall quickly so they don't float high above the shadow.
    tear.Height = stats.EmeraldHeight or -22
    tear.FallingSpeed = 0
    tear.FallingAcceleration = stats.EmeraldFallingAcceleration or 0.1

    if opts.spectral then
        tear:AddTearFlags(TearFlags.TEAR_SPECTRAL)
    end
    if opts.piercing then
        tear:AddTearFlags(TearFlags.TEAR_PIERCING)
    end

    applySpriteRotation(tear)
    local data = tear:GetData()
    data.jjbaEmerald = true
    data.breakScale = tear.Scale

    return entity
end

local function fitRadioTelegraph(effect)
    if not effect or not effect:Exists() then
        return
    end

    local topLeft, bottomRight = roomLayout.getEffectiveRoomRect()
    local size = bottomRight - topLeft
    local sprite = effect:GetSprite()
    -- Stretch to the effective room rect (deformation OK).
    sprite.Scale = Vector((size.X / RADIO_BASE_W) * 1.05, (size.Y / RADIO_BASE_H) * 1.05)
    -- Use effective-rect center (not GetCenterPos) so L / thin rooms don't skew the overlay.
    effect.Position = (topLeft + bottomRight) * 0.5
    effect.Velocity = Vector.Zero
end

local function setRadioTelegraphAlpha(effect, alpha)
    if not effect or not effect:Exists() then
        return
    end
    local sprite = effect:GetSprite()
    sprite.Color = Color(1, 1, 1, alpha)
end

local function spawnRadioEffect(position)
    ensureVariants()

    local room = game:GetRoom()
    local spawnPos = position or room:GetCenterPos()
    local variant = variants.radio
    local entity
    if not variant or variant < 0 then
        entity = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.NULL, 0, spawnPos, Vector(0, 0), nil)
    else
        entity = Isaac.Spawn(EntityType.ENTITY_EFFECT, variant, TEAR_SUBTYPE, spawnPos, Vector(0, 0), nil)
    end

    fitRadioTelegraph(entity)
    setRadioTelegraphAlpha(entity, 0)
    return entity
end

local function onTearUpdate(tear)
    local data = tear:GetData()
    if not data.jjbaEmerald then
        return
    end

    applySpriteRotation(tear)

    -- Floor impact when the tear lands (spectral tears often never hit walls).
    if tear.Height >= LAND_HEIGHT then
        trySpawnBreakFromTear(tear, true)
    end
end

local function onTearCollision(tear, collider)
    local data = tear:GetData()
    if not data.jjbaEmerald then
        return
    end
    if not collider or collider:ToPlayer() then
        return
    end

    -- Non-piercing: one Break then the tear dies. Piercing: flash on each hit.
    local piercing = tear:HasTearFlags(TearFlags.TEAR_PIERCING)
    trySpawnBreakFromTear(tear, not piercing)
end

--- Covers any tear death path that skipped collision / floor checks.
local function onTearRemove(entity)
    if entity.Type ~= EntityType.ENTITY_TEAR then
        return
    end

    local data = entity:GetData()
    if not data.jjbaEmerald then
        return
    end

    trySpawnBreakFromTear(entity, true)
end

local function onBreakEffectUpdate(effect)
    local data = effect:GetData()
    if not data.jjbaEmeraldBreak then
        return
    end

    local sprite = effect:GetSprite()
    if not sprite:IsPlaying(BREAK_ANIM) and sprite:IsFinished(BREAK_ANIM) then
        effect:Remove()
    end
end

return {
    vecFromAngle = vecFromAngle,
    spawnTear = spawnEmeraldTear,
    spawnRadioEffect = spawnRadioEffect,
    fitRadioTelegraph = fitRadioTelegraph,
    setRadioTelegraphAlpha = setRadioTelegraphAlpha,
    onTearUpdate = onTearUpdate,
    onTearCollision = onTearCollision,
    onTearRemove = onTearRemove,
    onBreakEffectUpdate = onBreakEffectUpdate,
    init = ensureVariants,
}
