local emeraldEntities = require("kakyoin.emerald_entities")
local emeraldSplash = require("kakyoin.emerald_splash")
local roomLayout = require("kakyoin.room_layout")

local JSF = _G.JoJoStandFramework
local game = Game()
local sfx = SFXManager()

local EMERALD_SPEED = 25
local DEFAULT_PER_FRAME = 3
local DEFAULT_MARGIN = 80
local DEFAULT_HP_FLOOR = 1
local DEFAULT_KURAE_FRAMES = 23
local DEFAULT_LAYOUT_FRAMES = 51
local DEFAULT_RAIN_FRAMES = 76
local DEFAULT_TRAIL_COUNT = 6
local DEFAULT_TRAIL_SPEED = 28
local DEFAULT_TRAIL_HOLD_FRAMES = 18
local DEFAULT_TRAIL_FADE_FRAMES = 45
local DEFAULT_EDGE_TRAIL_MAX = 18
local DEFAULT_LAYOUT_EDGE_PER_TICK = 1
local DEFAULT_LAYOUT_EDGE_INTERVAL = 3
local DEFAULT_LAYOUT_EDGE_HOLD = 8
local DEFAULT_LAYOUT_EDGE_FADE = 14
local DEFAULT_LAYOUT_EDGE_OSC_AMPLITUDE = 22
local DEFAULT_LAYOUT_EDGE_OSC_SPEED = 0.5
local DEFAULT_RAIN_EDGE_CHANCE = 0.45
local DEFAULT_RAIN_EDGE_HOLD = 3
local DEFAULT_RAIN_EDGE_FADE = 5
local RAIN_END_FADE_FRAMES = 8
local RAIN_SHAKE_TIMEOUT = 10
local SCALE_JITTER_MIN = 0.7
local SCALE_JITTER_RANGE = 0.6
local IDLE_ANIMS = { "IdleE", "IdleS", "IdleW", "IdleN" }
local PARTICLE_ANIMS = { "ParticleE", "ParticleS", "ParticleW", "ParticleN" }

local TRAIL_KIND = {
    LAYOUT = "layout",
    RAIN = "rain",
}

local PHASE = {
    KURAE = "kurae",
    LAYOUT = "layout",
    RAIN = "rain",
}

local EDGE = {
    TOP = 1,
    RIGHT = 2,
    BOTTOM = 3,
    LEFT = 4,
}

local function getPhaseDurations(stats)
    local kurae = stats.RadioKuraeFrames or DEFAULT_KURAE_FRAMES
    local layout = stats.RadioLayoutFrames or DEFAULT_LAYOUT_FRAMES
    local rain = stats.RadioRainFrames or stats.RadioBurstFrames or DEFAULT_RAIN_FRAMES
    return kurae, layout, rain, kurae + layout + rain
end

local function resolvePhase(elapsed, kurae, layout, rain)
    if elapsed < kurae then
        return PHASE.KURAE, elapsed, kurae
    end
    if elapsed < kurae + layout then
        return PHASE.LAYOUT, elapsed - kurae, layout
    end
    return PHASE.RAIN, elapsed - kurae - layout, rain
end

--- Fade in over the full layout phase (20 meters audio); stay visible through rain.
local function telegraphAlpha(phase, layoutElapsed, layoutDuration, rainElapsed, rainDuration)
    if phase == PHASE.LAYOUT then
        local t = layoutElapsed / math.max(1, layoutDuration)
        t = math.max(0, math.min(1, t))
        return t * t * (3 - 2 * t)
    end
    if phase == PHASE.RAIN then
        if rainElapsed >= rainDuration - RAIN_END_FADE_FRAMES then
            return math.max(0, (rainDuration - rainElapsed) / RAIN_END_FADE_FRAMES)
        end
        return 1
    end
    return 0
end

local function edgePointOnRect(topLeft, bottomRight, edge, t)
    t = math.max(0, math.min(1, t))
    if edge == EDGE.TOP then
        return Vector(topLeft.X + t * (bottomRight.X - topLeft.X), topLeft.Y)
    end
    if edge == EDGE.RIGHT then
        return Vector(bottomRight.X, topLeft.Y + t * (bottomRight.Y - topLeft.Y))
    end
    if edge == EDGE.BOTTOM then
        return Vector(topLeft.X + t * (bottomRight.X - topLeft.X), bottomRight.Y)
    end
    return Vector(topLeft.X, topLeft.Y + t * (bottomRight.Y - topLeft.Y))
end

local function edgeInwardNormal(edge)
    if edge == EDGE.TOP then
        return Vector(0, 1)
    end
    if edge == EDGE.RIGHT then
        return Vector(-1, 0)
    end
    if edge == EDGE.BOTTOM then
        return Vector(0, -1)
    end
    return Vector(1, 0)
end

local function pickRandomPerimeterSlot()
    local topLeft, bottomRight = roomLayout.getEffectiveRoomRect()
    local edge = math.random(1, 4)
    local t = 0.05 + math.random() * 0.9
    return edge, edgePointOnRect(topLeft, bottomRight, edge, t)
end

local function pickLayoutPerimeterSlot(layoutElapsed, layoutDuration)
    local topLeft, bottomRight = roomLayout.getEffectiveRoomRect()
    local progress = layoutElapsed / math.max(1, layoutDuration)
    local sweep = progress * 4
    local edge = (math.floor(sweep) % 4) + 1
    local t = sweep % 1
    t = math.max(0, math.min(1, t + (math.random() - 0.5) * 0.2))
    return edge, edgePointOnRect(topLeft, bottomRight, edge, t)
end

local function pickTrailTargets(count)
    local topLeft, bottomRight = roomLayout.getEffectiveRoomRect()
    local edges = { EDGE.TOP, EDGE.RIGHT, EDGE.BOTTOM, EDGE.LEFT }
    local points = {}
    for i = 1, count do
        local edge = edges[((i - 1) % 4) + 1]
        local t = 0.12 + math.random() * 0.76
        points[#points + 1] = edgePointOnRect(topLeft, bottomRight, edge, t)
    end
    return points
end

local function cleanupRadioTrails(standData)
    if not standData.radioTrails then
        return
    end
    for _, entity in ipairs(standData.radioTrails) do
        if entity and entity:Exists() then
            entity:Remove()
        end
    end
    standData.radioTrails = nil
end

local function cleanupRadioEdgeTrails(standData)
    if not standData.radioEdgeTrails then
        return
    end
    for _, entity in ipairs(standData.radioEdgeTrails) do
        if entity and entity:Exists() then
            entity:Remove()
        end
    end
    standData.radioEdgeTrails = nil
end

local function countAliveEdgeTrails(standData)
    if not standData.radioEdgeTrails then
        return 0
    end
    local count = 0
    for _, entity in ipairs(standData.radioEdgeTrails) do
        if entity and entity:Exists() then
            count = count + 1
        end
    end
    return count
end

local function playTrailAnim(sprite, velocity, useParticleAnim)
    if not JSF or not JSF.Combat or not JSF.Combat.utils then
        sprite:Play(useParticleAnim and "ParticleS" or "IdleS")
        return
    end
    local dirIndex = JSF.Combat.utils:VecDir(velocity) + 1
    local anims = useParticleAnim and PARTICLE_ANIMS or IDLE_ANIMS
    sprite:Play(anims[dirIndex] or anims[2])
end

local function spawnEdgeTrail(standDef, standData, stats, position, velocity, trailKind, peakAlpha, facingDir)
    if not JSF or not JSF.Entities then
        return nil
    end

    local maxAlive = stats.RadioEdgeTrailMax or DEFAULT_EDGE_TRAIL_MAX
    if countAliveEdgeTrails(standData) >= maxAlive then
        return nil
    end

    local particle = JSF.Entities.Spawn(standDef, JSF.Entities.KIND_PARTICLE, position, velocity, nil)
    if not particle or not particle:Exists() then
        return nil
    end

    local sprite = particle:GetSprite()
    playTrailAnim(sprite, facingDir or velocity, trailKind == TRAIL_KIND.RAIN)
    local alpha = peakAlpha or 0.55
    local color = Color(1, 1, 1, alpha, 0, 0, 0)
    sprite.Color = color
    particle.Color = color

    local data = particle:GetData()
    data.jjbaManagedParticle = true
    data.jjbaEdgeTrailKind = trailKind
    data.jjbaEdgeTrailPeakAlpha = alpha

    standData.radioEdgeTrails = standData.radioEdgeTrails or {}
    standData.radioEdgeTrails[#standData.radioEdgeTrails + 1] = particle
    return particle
end

local function spawnKuraeTrails(standDef, standEntity, standData, stats)
    cleanupRadioTrails(standData)
    if not JSF or not JSF.Entities then
        return
    end

    local count = stats.RadioTrailCount or DEFAULT_TRAIL_COUNT
    local speed = stats.RadioTrailSpeed or DEFAULT_TRAIL_SPEED
    local origin = standEntity.Position
    local utils = JSF.Combat.utils
    standData.radioTrails = {}

    for _, target in ipairs(pickTrailTargets(count)) do
        local delta = target - origin
        local velocity = Vector.Zero
        if delta:Length() > 0.1 then
            velocity = delta:Normalized() * speed
        end

        local particle = JSF.Entities.Spawn(standDef, JSF.Entities.KIND_PARTICLE, origin, velocity, nil)
        if particle and particle:Exists() then
            particle.PositionOffset = standEntity.PositionOffset
            local sprite = particle:GetSprite()
            local dirIndex = utils:VecDir(velocity) + 1
            sprite:Play(IDLE_ANIMS[dirIndex] or "IdleS")
            local color = Color(1, 1, 1, 0.9, 0, 0, 0)
            sprite.Color = color
            particle.Color = color
            particle:GetData().jjbaManagedParticle = true
            standData.radioTrails[#standData.radioTrails + 1] = particle
        end
    end
end

local function applyTrailAlpha(entity, alpha)
    local color = Color(1, 1, 1, alpha, 0, 0, 0)
    entity.Color = color
    entity:GetSprite().Color = color
end

local function updateRadioTrails(standData, stats)
    if not standData.radioTrails then
        return
    end

    local holdFrames = stats.RadioTrailHoldFrames or DEFAULT_TRAIL_HOLD_FRAMES
    local fadeFrames = stats.RadioTrailFadeFrames or DEFAULT_TRAIL_FADE_FRAMES
    local alive = {}

    for _, entity in ipairs(standData.radioTrails) do
        if entity and entity:Exists() then
            local age = entity.FrameCount
            local alpha = 0.9
            if age <= holdFrames then
                alpha = 0.9
            elseif age < holdFrames + fadeFrames then
                local t = (age - holdFrames) / fadeFrames
                alpha = 0.9 * (1 - t)
            else
                entity:Remove()
            end

            if entity:Exists() then
                applyTrailAlpha(entity, alpha)
                alive[#alive + 1] = entity
            end
        end
    end

    standData.radioTrails = #alive > 0 and alive or nil
end

local function getEdgeTrailTiming(trailKind, stats)
    if trailKind == TRAIL_KIND.RAIN then
        return stats.RadioRainEdgeHoldFrames or DEFAULT_RAIN_EDGE_HOLD,
            stats.RadioRainEdgeFadeFrames or DEFAULT_RAIN_EDGE_FADE
    end
    return stats.RadioLayoutEdgeHoldFrames or DEFAULT_LAYOUT_EDGE_HOLD,
        stats.RadioLayoutEdgeFadeFrames or DEFAULT_LAYOUT_EDGE_FADE
end

local function updateLayoutEdgeOscillation(entity, data, stats)
    local anchor = data.jjbaEdgeAnchor
    local inward = data.jjbaEdgeInward
    if not anchor or not inward then
        entity.Velocity = Vector.Zero
        return
    end

    local age = entity.FrameCount
    local amplitude = data.jjbaEdgeOscAmplitude
        or stats.RadioLayoutEdgeOscAmplitude
        or DEFAULT_LAYOUT_EDGE_OSC_AMPLITUDE
    local oscSpeed = data.jjbaEdgeOscSpeed
        or stats.RadioLayoutEdgeOscSpeed
        or DEFAULT_LAYOUT_EDGE_OSC_SPEED
    local phase = data.jjbaEdgeOscPhase or 0

    -- 0 = on border, amplitude = max inward; never pushes past the edge to outside.
    local wave = math.sin(age * oscSpeed + phase)
    local offset = amplitude * (0.5 + 0.5 * wave)
    entity.Position = anchor + inward * offset
    entity.Velocity = Vector.Zero

    local motion = math.cos(age * oscSpeed + phase)
    if math.abs(motion) > 0.05 then
        playTrailAnim(entity:GetSprite(), inward * motion, false)
    end
end

local function updateRadioEdgeTrails(standData, stats)
    if not standData.radioEdgeTrails then
        return
    end

    local alive = {}
    for _, entity in ipairs(standData.radioEdgeTrails) do
        if entity and entity:Exists() then
            local data = entity:GetData()
            local trailKind = data.jjbaEdgeTrailKind or TRAIL_KIND.LAYOUT
            local holdFrames, fadeFrames = getEdgeTrailTiming(trailKind, stats)
            local peakAlpha = data.jjbaEdgeTrailPeakAlpha or 0.55
            local age = entity.FrameCount
            local alpha = peakAlpha

            if age > holdFrames then
                if age >= holdFrames + fadeFrames then
                    entity:Remove()
                else
                    alpha = peakAlpha * (1 - (age - holdFrames) / fadeFrames)
                end
            end

            if entity:Exists() then
                if trailKind == TRAIL_KIND.RAIN then
                    entity.Velocity = Vector.Zero
                elseif trailKind == TRAIL_KIND.LAYOUT then
                    updateLayoutEdgeOscillation(entity, data, stats)
                end
                applyTrailAlpha(entity, alpha)
                alive[#alive + 1] = entity
            end
        end
    end

    standData.radioEdgeTrails = #alive > 0 and alive or nil
end

local function tickLayoutEdgeTrails(standDef, standData, stats, layoutElapsed, layoutDuration, overlayAlpha)
    local interval = stats.RadioLayoutEdgeInterval or DEFAULT_LAYOUT_EDGE_INTERVAL
    if interval > 1 and (layoutElapsed % interval) ~= 0 then
        return
    end

    local progress = layoutElapsed / math.max(1, layoutDuration)
    local perTick = stats.RadioLayoutEdgeTrailsPerTick or DEFAULT_LAYOUT_EDGE_PER_TICK
    local count = perTick
    if progress > 0.35 and math.random() < progress then
        count = count + 1
    end
    if progress > 0.65 and math.random() < (progress - 0.65) * 2.5 then
        count = count + 1
    end

    local peakAlpha = 0.25 + 0.45 * overlayAlpha
    local oscAmplitude = stats.RadioLayoutEdgeOscAmplitude or DEFAULT_LAYOUT_EDGE_OSC_AMPLITUDE
    local oscSpeed = stats.RadioLayoutEdgeOscSpeed or DEFAULT_LAYOUT_EDGE_OSC_SPEED

    for i = 1, count do
        local edge, anchor
        if math.random() < 0.65 then
            edge, anchor = pickLayoutPerimeterSlot(layoutElapsed + i, layoutDuration)
        else
            edge, anchor = pickRandomPerimeterSlot()
        end

        local inward = edgeInwardNormal(edge)
        local particle = spawnEdgeTrail(
            standDef,
            standData,
            stats,
            anchor,
            Vector.Zero,
            TRAIL_KIND.LAYOUT,
            peakAlpha,
            inward
        )
        if particle then
            local data = particle:GetData()
            data.jjbaEdgeAnchor = Vector(anchor.X, anchor.Y)
            data.jjbaEdgeInward = inward
            data.jjbaEdgeOscAmplitude = oscAmplitude
            data.jjbaEdgeOscSpeed = oscSpeed
            data.jjbaEdgeOscPhase = math.random() * math.pi * 2
        end
    end
end

local function isValidRainTarget(en)
    return en
        and en:Exists()
        and not en:IsDead()
        and en:IsVulnerableEnemy()
        and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
        and en.HitPoints > 0
end

local function collectRainTargets(hpFloor)
    local targets = {}
    local totalWeight = 0
    local entities = Isaac.GetRoomEntities()

    for _, en in ipairs(entities) do
        if isValidRainTarget(en) then
            local weight = math.max(en.HitPoints, hpFloor)
            targets[#targets + 1] = { entity = en, weight = weight }
            totalWeight = totalWeight + weight
        end
    end

    local topLeft, bottomRight = roomLayout.getEffectiveRoomRect()
    return targets, totalWeight, (topLeft + bottomRight) * 0.5
end

local function pickWeightedTarget(targets, totalWeight, fallbackPos)
    if #targets == 0 or totalWeight <= 0 then
        return fallbackPos
    end

    local roll = math.random() * totalWeight
    local acc = 0
    for _, entry in ipairs(targets) do
        acc = acc + entry.weight
        if roll <= acc and entry.entity:Exists() and not entry.entity:IsDead() then
            return entry.entity.Position
        end
    end

    local last = targets[#targets]
    if last and last.entity:Exists() then
        return last.entity.Position
    end
    return fallbackPos
end

local function offscreenSpawnToward(targetPos, margin)
    local topLeft, bottomRight = roomLayout.getEffectiveRoomRect()
    local center = (topLeft + bottomRight) * 0.5
    local toTarget = targetPos - center

    local edge
    if math.abs(toTarget.X) > math.abs(toTarget.Y) then
        edge = toTarget.X >= 0 and EDGE.LEFT or EDGE.RIGHT
    else
        edge = toTarget.Y >= 0 and EDGE.TOP or EDGE.BOTTOM
    end

    if math.random() < 0.25 then
        edge = math.random(1, 4)
    end

    local x = targetPos.X
    local y = targetPos.Y
    if edge == EDGE.TOP then
        x = topLeft.X + math.random() * (bottomRight.X - topLeft.X)
        y = topLeft.Y - margin
    elseif edge == EDGE.RIGHT then
        x = bottomRight.X + margin
        y = topLeft.Y + math.random() * (bottomRight.Y - topLeft.Y)
    elseif edge == EDGE.BOTTOM then
        x = topLeft.X + math.random() * (bottomRight.X - topLeft.X)
        y = bottomRight.Y + margin
    else
        x = topLeft.X - margin
        y = topLeft.Y + math.random() * (bottomRight.Y - topLeft.Y)
    end

    return Vector(x, y)
end

local function spawnRainEmerald(player, standDef, standData, stats)
    local perFrame = stats.RadioEmeraldsPerFrame or DEFAULT_PER_FRAME
    local margin = stats.RadioSpawnMargin or DEFAULT_MARGIN
    local hpFloor = stats.RadioTargetHpFloor or DEFAULT_HP_FLOOR
    local trailChance = stats.RadioRainEdgeTrailChance or DEFAULT_RAIN_EDGE_CHANCE
    local targets, totalWeight, centerPos = collectRainTargets(hpFloor)

    for _ = 1, perFrame do
        local targetPos = pickWeightedTarget(targets, totalWeight, centerPos)
        local spawnPos = offscreenSpawnToward(targetPos, margin)
        local delta = targetPos - spawnPos
        local velocity
        if delta:Length() < 0.1 then
            velocity = Vector.FromAngle(math.random() * 360) * EMERALD_SPEED
        else
            velocity = delta:Normalized() * EMERALD_SPEED
        end

        if math.random() < trailChance then
            spawnEdgeTrail(standDef, standData, stats, spawnPos, Vector.Zero, TRAIL_KIND.RAIN, 0.65, velocity)
        end

        emeraldEntities.spawnTear(
            player,
            spawnPos,
            velocity,
            standData.damage or 1,
            stats,
            {
                clampSpawn = false,
                spectral = true,
                piercing = true,
                scaleMult = SCALE_JITTER_MIN + math.random() * SCALE_JITTER_RANGE,
            }
        )
    end
end

local function onPhaseEnter(phase, sounds, standData, standEntity, standDef, stats)
    if phase == PHASE.KURAE then
        spawnKuraeTrails(standDef, standEntity, standData, stats)
        if sounds.kurae then
            sfx:Play(sounds.kurae, 1, 0, false, 1)
        end
        return
    end

    if phase == PHASE.LAYOUT then
        if not standData.radioEntity or not standData.radioEntity:Exists() then
            standData.radioEntity = emeraldEntities.spawnRadioEffect(game:GetRoom():GetCenterPos())
            standData.radioOrigin = standEntity.Position
            if not standData.damage then
                standData.damage = 1
            end
        end
        if sounds.twentyMeters then
            sfx:Play(sounds.twentyMeters, 1, 0, false, 1)
        end
        return
    end

    if phase == PHASE.RAIN then
        if sounds.emeraldoSplashuo then
            sfx:Play(sounds.emeraldoSplashuo, 1, 0, false, 1)
        end
    end
end

return function(player, standDef, jsf, shootDir)
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local sounds = standDef.sounds
    local stats = standDef.stats

    if standData.behavior ~= "radio" then
        return
    end

    local kuraeFrames, layoutFrames, rainFrames, totalFrames = getPhaseDurations(stats)
    local maxFrames = standData.radioMaxFrames or totalFrames

    if not standData.radioFrames or standData.radioFrames <= 0 then
        standData.radioFrames = maxFrames
    end

    local elapsed = maxFrames - standData.radioFrames
    local phase, phaseElapsed, phaseDuration = resolvePhase(elapsed, kuraeFrames, layoutFrames, rainFrames)
    local layoutElapsed = math.max(0, elapsed - kuraeFrames)
    local rainElapsed = math.max(0, elapsed - kuraeFrames - layoutFrames)

    if standData.radioPhase ~= phase then
        standData.radioPhase = phase
        onPhaseEnter(phase, sounds, standData, standEntity, standDef, stats)
    end

    if phase == PHASE.KURAE then
        local t = phaseElapsed / math.max(1, phaseDuration)
        standData.alphagoal = -100 * t
    else
        standData.alphagoal = -100
    end

    updateRadioTrails(standData, stats)
    updateRadioEdgeTrails(standData, stats)

    if phase == PHASE.LAYOUT or phase == PHASE.RAIN then
        if standData.radioEntity and standData.radioEntity:Exists() then
            emeraldEntities.fitRadioTelegraph(standData.radioEntity)
            local overlayAlpha = telegraphAlpha(phase, layoutElapsed, layoutFrames, rainElapsed, rainFrames)
            emeraldEntities.setRadioTelegraphAlpha(standData.radioEntity, overlayAlpha)
            if phase == PHASE.LAYOUT then
                tickLayoutEdgeTrails(standDef, standData, stats, layoutElapsed, layoutFrames, overlayAlpha)
            end
        end
    end

    if phase == PHASE.RAIN then
        spawnRainEmerald(player, standDef, standData, stats)
        game:ShakeScreen(stats.RadioRainShakeTimeout or RAIN_SHAKE_TIMEOUT)
    end

    standData.radioFrames = standData.radioFrames - 1

    if standData.radioFrames <= 0 then
        cleanupRadioTrails(standData)
        cleanupRadioEdgeTrails(standData)
        if standData.radioEntity and standData.radioEntity:Exists() then
            standData.radioEntity:Remove()
        end
        standData.radioEntity = nil
        standData.radioOrigin = nil
        standData.radioMaxFrames = nil
        standData.radioPhase = nil
        standData.behavior = "return"
        emeraldSplash.onSuperComplete(player, jsf)
    end
end
