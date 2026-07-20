local emeraldEntities = require("kakyoin.emerald_entities")
local emeraldSplash = require("kakyoin.emerald_splash")
local radioNet = require("kakyoin.radio_net")
local roomLayout = require("kakyoin.room_layout")

local JSF = _G.JoJoStandFramework
local Audio = JSF.Audio
local game = Game()

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
local DEFAULT_WEAVER_INITIAL = 2
local DEFAULT_WEAVER_INTERVAL_START = 6
local DEFAULT_WEAVER_INTERVAL_END = 1
local DEFAULT_WEAVER_SPEED_START = 52
local DEFAULT_WEAVER_SPEED_END = 56
local DEFAULT_WEAVER_MAX_ALIVE = 5
local DEFAULT_WEAVER_FADE = 6
local DEFAULT_WEAVER_ALPHA = 0.4
local DEFAULT_WEAVER_NEAR = 48
local DEFAULT_GHOST_GROW = 3
local DEFAULT_EDGE_TRAIL_MAX = 18
local DEFAULT_LAYOUT_EDGE_PER_TICK = 1
local DEFAULT_LAYOUT_EDGE_INTERVAL = 3
local DEFAULT_LAYOUT_EDGE_HOLD = 8
local DEFAULT_LAYOUT_EDGE_FADE = 14
local DEFAULT_LAYOUT_EDGE_OSC_AMPLITUDE = 22
local DEFAULT_LAYOUT_EDGE_OSC_SPEED = 0.5
local DEFAULT_RAIN_EDGE_CHANCE = 0.35
local DEFAULT_RAIN_EDGE_HOLD = 3
local DEFAULT_RAIN_EDGE_FADE = 5
local DEFAULT_RAIN_OFFSCREEN_CHANCE = 0.12
local DEFAULT_RAIN_SPLASH_ANIM_CHANCE = 0.28
local DEFAULT_RAIN_INWARD_NUDGE = 10
local RAIN_END_FADE_FRAMES = 8
local RAIN_SHAKE_TIMEOUT = 10
local SCALE_JITTER_MIN = 0.7
local SCALE_JITTER_RANGE = 0.6
local IDLE_ANIMS = { "IdleE", "IdleS", "IdleW", "IdleN" }
local PARTICLE_ANIMS = { "ParticleE", "ParticleS", "ParticleW", "ParticleN" }
--- VecDir 0..3 → E,S,W,N (matches anim.dirSuffix).
local LAUNCH_DIRS = {
    [0] = Vector(1, 0),
    [1] = Vector(0, 1),
    [2] = Vector(-1, 0),
    [3] = Vector(0, -1),
}

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

local function cleanupRadioWeavers(standData)
    if standData.radioWeavers then
        for _, weaver in ipairs(standData.radioWeavers) do
            if weaver.entity and weaver.entity:Exists() then
                weaver.entity:Remove()
            end
            if weaver.liveId then
                radioNet.clearLiveSegment(standData, weaver.liveId)
            end
        end
    end
    standData.radioWeavers = nil
    standData.radioWeaveQueue = nil
    standData.radioWeaveCooldown = nil
    standData.radioWeaveElapsed = nil
    standData.radioWeaverLiveId = nil
    standData.radioWeaveStandDef = nil
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

local function cleanupRainMuzzles(standData)
    if not standData.radioRainMuzzles then
        return
    end
    for _, entity in ipairs(standData.radioRainMuzzles) do
        if entity and entity:Exists() then
            entity:Remove()
        end
    end
    standData.radioRainMuzzles = nil
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

local function applyTrailAlpha(entity, alpha)
    local color = Color(1, 1, 1, alpha, 0, 0, 0)
    entity.Color = color
    entity:GetSprite().Color = color
end

local function shuffleInPlace(list)
    for i = #list, 2, -1 do
        local j = 1 + math.floor(math.random() * i)
        list[i], list[j] = list[j], list[i]
    end
end

local function countActiveWeavers(standData)
    if not standData.radioWeavers then
        return 0
    end
    local n = 0
    for _, weaver in ipairs(standData.radioWeavers) do
        if weaver.entity and weaver.entity:Exists() and not weaver.done then
            n = n + 1
        end
    end
    return n
end

local function weaveProgress01(standData, stats)
    local kurae = stats.RadioKuraeFrames or DEFAULT_KURAE_FRAMES
    local layout = stats.RadioLayoutFrames or DEFAULT_LAYOUT_FRAMES
    local duration = math.max(1, kurae + layout)
    local elapsed = standData.radioWeaveElapsed or 0
    return math.max(0, math.min(1, elapsed / duration))
end

local function weaverIntervalForProgress(t, stats)
    local a = stats.RadioWeaverIntervalStart or DEFAULT_WEAVER_INTERVAL_START
    local b = stats.RadioWeaverIntervalEnd or DEFAULT_WEAVER_INTERVAL_END
    -- Reach min interval ~3x sooner than linear weave progress.
    local rushed = math.min(1, t * 3)
    local eased = 1 - (1 - rushed) * (1 - rushed)
    return math.max(1, a + (b - a) * eased)
end

local function weaverSpeedForProgress(t, stats)
    local a = stats.RadioWeaverSpeedStart or DEFAULT_WEAVER_SPEED_START
    local b = stats.RadioWeaverSpeedEnd or DEFAULT_WEAVER_SPEED_END
    return a + (b - a) * t
end

local function takeNextWeaveSegment(standData)
    local queue = standData.radioWeaveQueue
    if not queue or #queue == 0 then
        return nil
    end
    return table.remove(queue, 1)
end

local function weaverNearPoint(standData, point, radius)
    if not standData.radioWeavers or not point then
        return false
    end
    local r2 = radius * radius
    for _, weaver in ipairs(standData.radioWeavers) do
        if weaver.entity and weaver.entity:Exists() and not weaver.done then
            local d = weaver.entity.Position - point
            local lenSq = d.X * d.X + d.Y * d.Y
            if lenSq <= r2 then
                return true
            end
        end
    end
    return false
end

local function prioritizeWeaveQueue(queue)
    table.sort(queue, function(a, b)
        local aw = a.preferWeaver and 1 or 0
        local bw = b.preferWeaver and 1 or 0
        if aw ~= bw then
            return aw > bw
        end
        return (a.length or 0) > (b.length or 0)
    end)
    -- Light shuffle within preferWeaver / non-prefer bands so it doesn't look sorted.
    local i = 1
    while i <= #queue do
        local prefer = queue[i].preferWeaver and true or false
        local j = i
        while j <= #queue and ((queue[j].preferWeaver and true or false) == prefer) do
            j = j + 1
        end
        for k = j - 1, i + 1, -1 do
            local r = i + math.floor(math.random() * (k - i + 1))
            queue[k], queue[r] = queue[r], queue[k]
        end
        i = j
    end
end

local function shouldSpawnWeaver(standData, stats, seg, t)
    local maxAlive = stats.RadioWeaverMaxAlive or DEFAULT_WEAVER_MAX_ALIVE
    if countActiveWeavers(standData) >= maxAlive then
        return false
    end
    local near = stats.RadioWeaverNearRadius or DEFAULT_WEAVER_NEAR
    if weaverNearPoint(standData, seg.from, near) then
        return false
    end

    -- Bias: long/chord prefer weaver; late weave + min interval → more ghosts.
    local chance
    if seg.preferWeaver then
        chance = 0.78 - t * 0.25
    else
        chance = 0.42 - t * 0.28
    end
    if t > 0.65 then
        chance = chance * 0.55
    end
    return math.random() < math.max(0.08, chance)
end

local function stampAlpha(standData, stats)
    return standData.radioNetStampAlpha
        or (stats and stats.RadioNetStampAlpha)
        or 0.85
end

local function spawnGhostStrand(standData, stats, seg)
    local grow = stats.RadioNetGhostGrowFrames or DEFAULT_GHOST_GROW
    -- Shorter strands grow faster.
    if (seg.length or 0) < 160 then
        grow = math.max(1, grow - 1)
    end
    radioNet.startGhost(standData, seg.from, seg.to, seg.variant, grow)
end

local function spawnOneWeaver(standDef, standEntity, standData, stats, seg, fromStand)
    if not JSF or not JSF.Entities or not seg then
        return false
    end

    local t = weaveProgress01(standData, stats)
    local speed = weaverSpeedForProgress(t, stats)
    local origin
    if fromStand then
        origin = standEntity.Position
    else
        origin = seg.from
    end

    local waypoints = { Vector(origin.X, origin.Y) }
    if fromStand and (origin - seg.from):Length() > 8 then
        waypoints[#waypoints + 1] = seg.from
    elseif not fromStand then
        -- Already at seg.from; only travel to end.
    else
        -- fromStand but already near from
    end
    if (waypoints[#waypoints] - seg.to):Length() > 1 then
        waypoints[#waypoints + 1] = seg.to
    end
    if #waypoints < 2 then
        waypoints = { Vector(seg.from.X, seg.from.Y), Vector(seg.to.X, seg.to.Y) }
        origin = seg.from
    end

    local launchDir = waypoints[2] - waypoints[1]
    local particle = JSF.Entities.Spawn(standDef, JSF.Entities.KIND_PARTICLE, waypoints[1], Vector.Zero, nil)
    if not particle or not particle:Exists() then
        return false
    end

    particle.PositionOffset = standEntity.PositionOffset
    local sprite = particle:GetSprite()
    playTrailAnim(sprite, launchDir, false)
    local peakAlpha = stats.RadioWeaverAlpha or DEFAULT_WEAVER_ALPHA
    local color = Color(1, 1, 1, peakAlpha, 0, 0, 0)
    sprite.Color = color
    particle.Color = color
    particle:GetData().jjbaManagedParticle = true
    particle:GetData().jjbaRadioWeaver = true

    standData.radioWeaverLiveId = (standData.radioWeaverLiveId or 0) + 1
    standData.radioWeavers = standData.radioWeavers or {}
    standData.radioWeavers[#standData.radioWeavers + 1] = {
        entity = particle,
        waypoints = waypoints,
        waypointIndex = 2,
        segFrom = Vector(waypoints[1].X, waypoints[1].Y),
        liveId = standData.radioWeaverLiveId,
        variant = seg.variant or (1 + (standData.radioWeaverLiveId % 3)),
        speed = speed,
        peakAlpha = peakAlpha,
        done = false,
        fadeFrames = 0,
    }
    return true
end

local function beginWeave(standDef, standEntity, standData, stats)
    cleanupRadioWeavers(standData)
    cleanupRadioTrails(standData)
    radioNet.create(standData, stats)

    local queue = {}
    for _, seg in ipairs(standData.radioNetPlan or {}) do
        queue[#queue + 1] = seg
    end
    prioritizeWeaveQueue(queue)

    standData.radioWeaveQueue = queue
    standData.radioWeavers = {}
    standData.radioWeaverLiveId = 0
    standData.radioWeaveElapsed = 0
    standData.radioOrigin = standEntity.Position
    standData.radioWeaveStandDef = standDef

    local initial = stats.RadioWeaverInitialCount or DEFAULT_WEAVER_INITIAL
    for _ = 1, initial do
        local seg = takeNextWeaveSegment(standData)
        if not seg then
            break
        end
        spawnOneWeaver(standDef, standEntity, standData, stats, seg, true)
    end

    standData.radioWeaveCooldown = weaverIntervalForProgress(0, stats)
end

local function tickWeaveSpawner(standDef, standEntity, standData, stats, allowSpawn)
    if not standData.radioWeaveQueue then
        return
    end

    standData.radioWeaveElapsed = (standData.radioWeaveElapsed or 0) + 1
    radioNet.updateGhosts(standData)

    if not allowSpawn then
        return
    end

    local queue = standData.radioWeaveQueue
    if #queue == 0 then
        return
    end

    standData.radioWeaveCooldown = (standData.radioWeaveCooldown or 0) - 1
    if standData.radioWeaveCooldown > 0 then
        return
    end

    local t = weaveProgress01(standData, stats)
    local burst = 1
    if t > 0.15 and math.random() < t + 0.2 then
        burst = 2
    end
    if t > 0.4 then
        burst = math.max(burst, 2)
    end
    if t > 0.65 then
        burst = 3
    end

    for _ = 1, burst do
        local seg = takeNextWeaveSegment(standData)
        if not seg then
            break
        end
        if shouldSpawnWeaver(standData, stats, seg, t) then
            spawnOneWeaver(standDef, standEntity, standData, stats, seg, false)
        else
            spawnGhostStrand(standData, stats, seg)
        end
    end

    standData.radioWeaveCooldown = weaverIntervalForProgress(weaveProgress01(standData, stats), stats)
end

local function updateWeavers(standData, stats)
    if not standData.radioWeavers then
        return
    end

    local fadeLen = stats.RadioWeaverFadeFrames or DEFAULT_WEAVER_FADE
    local alive = {}

    for _, weaver in ipairs(standData.radioWeavers) do
        local entity = weaver.entity
        local keep = true
        if not entity or not entity:Exists() then
            keep = false
        elseif weaver.done then
            weaver.fadeFrames = (weaver.fadeFrames or 0) + 1
            local fadeT = weaver.fadeFrames / math.max(1, fadeLen)
            local peak = weaver.peakAlpha or DEFAULT_WEAVER_ALPHA
            local alpha = math.max(0, peak * (1 - fadeT))
            applyTrailAlpha(entity, alpha)
            if alpha <= 0.02 then
                entity:Remove()
                radioNet.clearLiveSegment(standData, weaver.liveId)
                keep = false
            end
        else
            local target = weaver.waypoints[weaver.waypointIndex]
            if not target then
                weaver.done = true
            else
                local pos = entity.Position
                local delta = target - pos
                local dist = delta:Length()
                local step = weaver.speed or DEFAULT_WEAVER_SPEED_START
                playTrailAnim(entity:GetSprite(), delta, false)
                applyTrailAlpha(entity, weaver.peakAlpha or DEFAULT_WEAVER_ALPHA)

                if dist <= step then
                    entity.Position = target
                    entity.Velocity = Vector.Zero
                    radioNet.clearLiveSegment(standData, weaver.liveId)
                    radioNet.addSegment(
                        standData,
                        weaver.segFrom,
                        target,
                        stampAlpha(standData, stats),
                        weaver.variant
                    )
                    weaver.segFrom = Vector(target.X, target.Y)
                    weaver.waypointIndex = weaver.waypointIndex + 1
                    if weaver.waypointIndex > #weaver.waypoints then
                        weaver.done = true
                    end
                else
                    entity.Position = pos + delta:Normalized() * step
                    entity.Velocity = Vector.Zero
                    radioNet.updateLiveSegment(
                        standData,
                        weaver.liveId,
                        weaver.segFrom,
                        entity.Position,
                        stampAlpha(standData, stats),
                        weaver.variant
                    )
                end
            end
        end

        if keep then
            alive[#alive + 1] = weaver
        end
    end

    standData.radioWeavers = alive
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

local function vecToLaunchDir(vec)
    local utils = JSF and JSF.Combat and JSF.Combat.utils
    if utils then
        return LAUNCH_DIRS[utils:VecDir(vec)] or LAUNCH_DIRS[2]
    end
    return LAUNCH_DIRS[2]
end

--- Pick a point on the irregular net ring (section between two anchors).
local function pickRingSpawn(standData, targetPos, stats)
    local anchors = standData.radioNetAnchors
    if not anchors or #anchors < 2 then
        return nil
    end

    local n = #anchors
    standData.radioRainSection = ((standData.radioRainSection or 0) % n) + 1
    local i = standData.radioRainSection
    local j = (i % n) + 1
    local t = 0.15 + math.random() * 0.7
    local spawnPos = Vector(
        anchors[i].X + (anchors[j].X - anchors[i].X) * t,
        anchors[i].Y + (anchors[j].Y - anchors[i].Y) * t
    )

    local nudge = stats.RadioRainInwardNudge or DEFAULT_RAIN_INWARD_NUDGE
    if nudge > 0 and targetPos then
        local inward = targetPos - spawnPos
        if inward:Length() > 0.1 then
            spawnPos = spawnPos + inward:Normalized() * nudge
        end
    end

    return spawnPos
end

local function spawnRainSplashMuzzle(standDef, standData, position, velocity)
    if not JSF or not JSF.Entities then
        return nil
    end

    local particle = JSF.Entities.Spawn(standDef, JSF.Entities.KIND_PARTICLE, position, Vector.Zero, nil)
    if not particle or not particle:Exists() then
        return nil
    end

    local launchdir = vecToLaunchDir(velocity)
    local sprite = particle:GetSprite()
    if JSF.Combat and JSF.Combat.anim then
        JSF.Combat.anim.playDir(sprite, "SplashIn", launchdir)
    else
        playTrailAnim(sprite, velocity, true)
    end

    local color = Color(1, 1, 1, 0.8, 0, 0, 0)
    sprite.Color = color
    particle.Color = color
    particle:GetData().jjbaManagedParticle = true
    particle:GetData().jjbaRainSplashMuzzle = true

    standData.radioRainMuzzles = standData.radioRainMuzzles or {}
    standData.radioRainMuzzles[#standData.radioRainMuzzles + 1] = particle
    return particle
end

local function updateRainMuzzles(standData)
    if not standData.radioRainMuzzles then
        return
    end

    local animApi = JSF and JSF.Combat and JSF.Combat.anim
    local alive = {}
    for _, entity in ipairs(standData.radioRainMuzzles) do
        if entity and entity:Exists() then
            -- SplashIn is 3 frames; keep a small buffer.
            local done = entity.FrameCount >= 6
            if animApi then
                done = done or animApi.isFinishedDir(entity:GetSprite(), "SplashIn")
            end
            if done then
                entity:Remove()
            else
                alive[#alive + 1] = entity
            end
        end
    end
    standData.radioRainMuzzles = #alive > 0 and alive or nil
end

local function maybeRainSplashFeedback(standDef, standData, stats, spawnPos, velocity)
    local animChance = stats.RadioRainSplashAnimChance or DEFAULT_RAIN_SPLASH_ANIM_CHANCE
    if math.random() < animChance then
        spawnRainSplashMuzzle(standDef, standData, spawnPos, velocity)
    end
end

local function spawnRainEmerald(player, standDef, standData, stats)
    local perFrame = stats.RadioEmeraldsPerFrame or DEFAULT_PER_FRAME
    local margin = stats.RadioSpawnMargin or DEFAULT_MARGIN
    local hpFloor = stats.RadioTargetHpFloor or DEFAULT_HP_FLOOR
    local trailChance = stats.RadioRainEdgeTrailChance or DEFAULT_RAIN_EDGE_CHANCE
    local offscreenChance = stats.RadioRainOffscreenChance or DEFAULT_RAIN_OFFSCREEN_CHANCE
    local angleSpread = stats.SplashAngleSpread or 11
    local targets, totalWeight, centerPos = collectRainTargets(hpFloor)

    for _ = 1, perFrame do
        local targetPos = pickWeightedTarget(targets, totalWeight, centerPos)
        local spawnPos
        if math.random() < offscreenChance then
            spawnPos = offscreenSpawnToward(targetPos, margin)
        else
            spawnPos = pickRingSpawn(standData, targetPos, stats)
                or offscreenSpawnToward(targetPos, margin)
        end

        local delta = targetPos - spawnPos
        local velocity
        if delta:Length() < 0.1 then
            velocity = Vector.FromAngle(math.random() * 360) * EMERALD_SPEED
        else
            local angle = delta:GetAngleDegrees() + ((math.random() * 2) - 1) * angleSpread
            velocity = Vector.FromAngle(angle) * EMERALD_SPEED
        end

        if math.random() < trailChance then
            spawnEdgeTrail(standDef, standData, stats, spawnPos, Vector.Zero, TRAIL_KIND.RAIN, 0.55, velocity)
        end

        maybeRainSplashFeedback(standDef, standData, stats, spawnPos, velocity)

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
        if not standData.damage then
            standData.damage = 1
        end
        beginWeave(standDef, standEntity, standData, stats)
        if sounds.kurae then
            Audio.play(sounds.kurae)
        end
        return
    end

    if phase == PHASE.LAYOUT then
        if sounds.twentyMeters then
            Audio.play(sounds.twentyMeters)
        end
        return
    end

    if phase == PHASE.RAIN then
        -- No instant dump: keep weaving at max pace until the queue drains.
        standData.radioWeaveCooldown = 0
        standData.radioRainSection = 0
        radioNet.clearAllLive(standData)
        if sounds.emeraldoSplashuo then
            Audio.play(sounds.emeraldoSplashuo)
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

    if phase == PHASE.KURAE or phase == PHASE.LAYOUT then
        tickWeaveSpawner(standDef, standEntity, standData, stats, true)
        radioNet.setAlpha(standData, stampAlpha(standData, stats))
    elseif phase == PHASE.RAIN then
        local queueLeft = standData.radioWeaveQueue and #standData.radioWeaveQueue or 0
        local stillWeaving = queueLeft > 0
            or countActiveWeavers(standData) > 0
            or radioNet.countGhosts(standData) > 0
        if stillWeaving then
            standData.radioWeaveElapsed = (stats.RadioKuraeFrames or DEFAULT_KURAE_FRAMES)
                + (stats.RadioLayoutFrames or DEFAULT_LAYOUT_FRAMES)
            tickWeaveSpawner(standDef, standEntity, standData, stats, true)
        else
            radioNet.updateGhosts(standData)
        end
        local overlayAlpha = telegraphAlpha(phase, layoutElapsed, layoutFrames, rainElapsed, rainFrames)
        if overlayAlpha >= 0.99 then
            radioNet.pulse(standData, overlayAlpha, rainElapsed)
        else
            radioNet.setAlpha(standData, overlayAlpha)
        end
    end

    updateWeavers(standData, stats)
    updateRadioEdgeTrails(standData, stats)
    updateRainMuzzles(standData)

    if phase == PHASE.RAIN then
        spawnRainEmerald(player, standDef, standData, stats)
        game:ShakeScreen(stats.RadioRainShakeTimeout or RAIN_SHAKE_TIMEOUT)
    end

    standData.radioFrames = standData.radioFrames - 1

    if standData.radioFrames <= 0 then
        cleanupRadioWeavers(standData)
        cleanupRadioTrails(standData)
        cleanupRadioEdgeTrails(standData)
        cleanupRainMuzzles(standData)
        radioNet.destroy(standData)
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
