--- Procedural Hierophant Green net telegraph.
--- Segments are stamped as Hierophant weavers travel (trail), not fade-revealed.

local roomLayout = require("kakyoin.room_layout")

local SEGMENT_EFFECT_NAME = "HG Emerald Net"
local FALLBACK_EFFECT_NAME = "HG Emerald Break"
local ANM2_PATH = "gfx/kakyoin/net.anm2"
local FULL_WIDTH = 524
local DEFAULT_POINT_COUNT = 12
local DEFAULT_CHORD_COUNT = 3
local MIN_POINT_COUNT = 6
local MIN_CHORD_COUNT = 1
--- Approx perimeter of a 2x2 room AABB (stats counts are tuned for this size).
local REF_ROOM_PERIMETER = 3200
local POINT_JITTER = 0.03
local DEPTH_OFFSET = 180
local THREAD_SCALE_Y = 1
local DEFAULT_OUTSET_X = 28
local DEFAULT_OUTSET_Y = 36
local DEFAULT_OUTSET_JITTER = 18
local DEFAULT_STAMP_ALPHA = 0.85
local WEAVER_LENGTH_HINT = 220

local EDGE = {
    TOP = 1,
    RIGHT = 2,
    BOTTOM = 3,
    LEFT = 4,
}

local LENGTH_TIERS = {
    { name = "Short", width = 131 },
    { name = "Medium", width = 262 },
    { name = "Long", width = 393 },
    { name = "Full", width = FULL_WIDTH },
}

local VARIANT_COUNT = 3

local segmentVariant = nil

local function getSegmentVariant()
    if segmentVariant ~= nil then
        return segmentVariant
    end
    local named = Isaac.GetEntityVariantByName(SEGMENT_EFFECT_NAME)
    if named and named >= 0 then
        segmentVariant = named
        return segmentVariant
    end
    named = Isaac.GetEntityVariantByName(FALLBACK_EFFECT_NAME)
    if named and named >= 0 then
        segmentVariant = named
    else
        segmentVariant = 0
    end
    return segmentVariant
end

local function mulberry32(seed)
    local state = seed % 2147483647
    if state <= 0 then
        state = state + 2147483646
    end
    return function()
        state = (state * 48271) % 2147483647
        return state / 2147483647
    end
end

local function roomSize(topLeft, bottomRight)
    local w = math.max(1, bottomRight.X - topLeft.X)
    local h = math.max(1, bottomRight.Y - topLeft.Y)
    return w, h, 2 * (w + h)
end

local function clampInt(n, lo, hi)
    n = math.floor(n + 0.5)
    if n < lo then
        return lo
    end
    if n > hi then
        return hi
    end
    return n
end

--- Scale ring/chord density by real room perimeter (stats = max for ~2x2 / L).
local function densityForRoom(stats)
    local maxPoints = (stats and stats.RadioNetPointCount) or DEFAULT_POINT_COUNT
    local maxChords = (stats and stats.RadioNetChordCount) or DEFAULT_CHORD_COUNT
    local minPoints = (stats and stats.RadioNetPointCountMin) or MIN_POINT_COUNT
    local minChords = (stats and stats.RadioNetChordCountMin) or MIN_CHORD_COUNT
    local refPeri = (stats and stats.RadioNetRefPerimeter) or REF_ROOM_PERIMETER

    local topLeft, bottomRight = roomLayout.getRoomRect()
    local _, _, peri = roomSize(topLeft, bottomRight)
    local scale = peri / math.max(1, refPeri)
    if scale < 0.45 then
        scale = 0.45
    elseif scale > 1 then
        scale = 1
    end

    local points = clampInt(maxPoints * scale, minPoints, maxPoints)
    local chords = clampInt(maxChords * scale, minChords, maxChords)
    return points, chords
end

local function pointOnPerimeter(topLeft, bottomRight, dist)
    local w, h, peri = roomSize(topLeft, bottomRight)
    dist = dist % peri
    if dist < 0 then
        dist = dist + peri
    end
    if dist < w then
        return Vector(topLeft.X + dist, topLeft.Y), EDGE.TOP
    end
    if dist < w + h then
        return Vector(bottomRight.X, topLeft.Y + (dist - w)), EDGE.RIGHT
    end
    if dist < 2 * w + h then
        return Vector(bottomRight.X - (dist - w - h), bottomRight.Y), EDGE.BOTTOM
    end
    return Vector(topLeft.X, bottomRight.Y - (dist - 2 * w - h)), EDGE.LEFT
end

local function outwardNormal(edge)
    if edge == EDGE.TOP then
        return Vector(0, -1)
    end
    if edge == EDGE.RIGHT then
        return Vector(1, 0)
    end
    if edge == EDGE.BOTTOM then
        return Vector(0, 1)
    end
    return Vector(-1, 0)
end

local function baseOutsetForEdge(edge, outsetX, outsetY)
    if edge == EDGE.TOP or edge == EDGE.BOTTOM then
        return outsetY
    end
    return outsetX
end

--- Irregular ring anchors: room border + per-point outward outset (base + jitter).
local function samplePerimeterPoints(count, rng, outsetX, outsetY, outsetJitter)
    local topLeft, bottomRight = roomLayout.getRoomRect()
    local _, _, peri = roomSize(topLeft, bottomRight)

    local rawJitter = {}
    for i = 1, count do
        rawJitter[i] = rng() * outsetJitter
    end
    -- Soften adjacent depths so the ring doesn't look too jagged.
    local jitter = {}
    for i = 1, count do
        local prev = rawJitter[((i - 2) % count) + 1]
        local curr = rawJitter[i]
        local nxt = rawJitter[(i % count) + 1]
        jitter[i] = prev * 0.25 + curr * 0.5 + nxt * 0.25
    end

    local points = {}
    for i = 1, count do
        local u = ((i - 0.5) / count) + (rng() - 0.5) * POINT_JITTER
        u = (u % 1 + 1) % 1
        local border, edge = pointOnPerimeter(topLeft, bottomRight, u * peri)
        local depth = baseOutsetForEdge(edge, outsetX, outsetY) + jitter[i]
        local n = outwardNormal(edge)
        points[#points + 1] = border + n * depth
    end

    return points, topLeft, bottomRight
end

local function pickLengthTier(length)
    for _, tier in ipairs(LENGTH_TIERS) do
        if length <= tier.width then
            return tier
        end
    end
    return LENGTH_TIERS[#LENGTH_TIERS]
end

local function animName(variantIndex, tierName)
    return "Net " .. tostring(variantIndex) .. " " .. tierName
end

--- One plan strand = border anchor → border anchor.
--- Sprite length chaining happens only when drawing (addSegment), not in the weave queue.
local function appendPlanSegment(plan, from, to, kind, variantIndex)
    local delta = to - from
    local length = delta:Length()
    -- Drop tiny strands (jitter / near-duplicate anchors).
    if length < 40 then
        return
    end

    local tier = pickLengthTier(math.min(length, FULL_WIDTH))
    plan[#plan + 1] = {
        from = from,
        to = to,
        kind = kind,
        variant = variantIndex,
        tierName = tier.name,
        tierWidth = tier.width,
        length = length,
        preferWeaver = (kind == "chord" and length >= WEAVER_LENGTH_HINT * 0.75)
            or length >= WEAVER_LENGTH_HINT,
    }
end

local function buildSegmentPlan(points, _topLeft, _bottomRight, chordCount, rng)
    local plan = {}
    local n = #points
    if n < 2 then
        return plan
    end

    -- Closed irregular ring (all consecutive anchors, including same wall).
    for i = 1, n do
        local j = (i % n) + 1
        local variant = 1 + math.floor(rng() * VARIANT_COUNT)
        appendPlanSegment(plan, points[i], points[j], "rim", variant)
    end

    -- Near-diameter chords for spiderweb body.
    local half = math.max(2, math.floor(n / 2))
    for i = 1, n do
        local j = ((i - 1 + half) % n) + 1
        if i < j then
            local variant = 1 + math.floor(rng() * VARIANT_COUNT)
            appendPlanSegment(plan, points[i], points[j], "chord", variant)
        end
    end

    local chords = math.min(chordCount, math.max(0, n - 3))
    local used = {}
    local attempts = 0
    while #used < chords and attempts < chords * 8 do
        attempts = attempts + 1
        local i = 1 + math.floor(rng() * n)
        local span = 2 + math.floor(rng() * math.max(1, math.floor(n / 2) - 1))
        local j = ((i - 1 + span) % n) + 1
        local key = math.min(i, j) * 100 + math.max(i, j)
        if not used[key] and i ~= j then
            used[key] = true
            local variant = 1 + math.floor(rng() * VARIANT_COUNT)
            appendPlanSegment(plan, points[i], points[j], "chord", variant)
        end
    end

    return plan
end

local function makeSegDesc(from, to, variant)
    local length = (to - from):Length()
    local tier = pickLengthTier(length)
    return {
        from = Vector(from.X, from.Y),
        to = Vector(to.X, to.Y),
        kind = "trail",
        variant = variant or 1,
        tierName = tier.name,
        tierWidth = tier.width,
    }
end

local function fitSegmentSprite(entity, seg, alpha)
    if not entity or not entity:Exists() or not seg then
        return
    end

    local from = seg.from
    local to = seg.to
    local delta = to - from
    local length = delta:Length()
    if length < 1 then
        entity.Visible = false
        return
    end

    entity.Position = from
    entity.Velocity = Vector.Zero
    entity.Visible = true

    local tierWidth = seg.tierWidth or FULL_WIDTH
    local sprite = entity:GetSprite()
    sprite.PlaybackSpeed = 0
    sprite:SetFrame(0)
    sprite.Rotation = delta:GetAngleDegrees()
    sprite.Scale = Vector(length / tierWidth, THREAD_SCALE_Y)
    sprite.Color = Color(1, 1, 1, alpha)
end

local function spawnSegmentEntity(seg, alpha)
    local entity = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        getSegmentVariant(),
        0,
        seg.from,
        Vector.Zero,
        nil
    )
    if not entity or not entity:Exists() then
        return nil
    end

    local effect = entity:ToEffect()
    if effect then
        effect:SetTimeout(9999)
    end

    local sprite = entity:GetSprite()
    sprite:Load(ANM2_PATH, true)
    sprite:Play(animName(seg.variant or 1, seg.tierName or "Full"), true)
    sprite.PlaybackSpeed = 0
    sprite:SetFrame(0)

    entity.DepthOffset = DEPTH_OFFSET
    entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    entity:GetData().jjbaRadioNetSegment = true

    fitSegmentSprite(entity, seg, alpha)
    return entity
end

local function ensureSegmentLists(standData)
    standData.radioNetSegments = standData.radioNetSegments or {}
    standData.radioNetLive = standData.radioNetLive or {}
    standData.radioNetGhosts = standData.radioNetGhosts or {}
end

local radioNet = {}

function radioNet.create(standData, stats)
    radioNet.destroy(standData)

    local pointCount, chordCount = densityForRoom(stats)
    local outsetX = (stats and stats.RadioNetBorderOutsetX) or DEFAULT_OUTSET_X
    local outsetY = (stats and stats.RadioNetBorderOutsetY) or DEFAULT_OUTSET_Y
    local outsetJitter = (stats and stats.RadioNetOutsetJitter) or DEFAULT_OUTSET_JITTER
    local stampAlpha = (stats and stats.RadioNetStampAlpha) or DEFAULT_STAMP_ALPHA
    local seed = standData.radioNetSeed
    if not seed then
        seed = Random()
        standData.radioNetSeed = seed
    end

    local rng = mulberry32(seed)
    local points, topLeft, bottomRight = samplePerimeterPoints(
        pointCount,
        rng,
        outsetX,
        outsetY,
        outsetJitter
    )
    local plan = buildSegmentPlan(points, topLeft, bottomRight, chordCount, rng)

    standData.radioNetAnchors = points
    standData.radioNetPlan = plan
    standData.radioNetPointCount = pointCount
    standData.radioNetChordCount = chordCount
    standData.radioNetSegments = {}
    standData.radioNetLive = {}
    standData.radioNetGhosts = {}
    standData.radioNetGhostId = 0
    standData.radioNetAlpha = stampAlpha
    standData.radioNetStampAlpha = stampAlpha
end

function radioNet.destroy(standData)
    if standData.radioNetSegments then
        for _, entity in ipairs(standData.radioNetSegments) do
            if entity and entity:Exists() then
                entity:Remove()
            end
        end
    end
    if standData.radioNetLive then
        for _, entry in pairs(standData.radioNetLive) do
            if entry.entity and entry.entity:Exists() then
                entry.entity:Remove()
            end
        end
    end
    standData.radioNetPlan = nil
    standData.radioNetAnchors = nil
    standData.radioNetPointCount = nil
    standData.radioNetChordCount = nil
    standData.radioNetSegments = nil
    standData.radioNetLive = nil
    standData.radioNetGhosts = nil
    standData.radioNetGhostId = nil
    standData.radioNetReveal = nil
    standData.radioNetSeed = nil
    standData.radioNetAlpha = nil
    standData.radioNetStampAlpha = nil
end

--- Permanent trail stamp between two points (may chain if longer than Full).
function radioNet.addSegment(standData, from, to, alpha, variant)
    ensureSegmentLists(standData)
    alpha = alpha or standData.radioNetStampAlpha or standData.radioNetAlpha or DEFAULT_STAMP_ALPHA
    variant = variant or (1 + Random() % VARIANT_COUNT)

    local delta = to - from
    local length = delta:Length()
    if length < 1 then
        return
    end

    local pieces = math.max(1, math.ceil(length / FULL_WIDTH - 1e-6))
    local dir = delta * (1 / length)
    local pieceLen = length / pieces

    for p = 1, pieces do
        local a = from + dir * ((p - 1) * pieceLen)
        local b = from + dir * (p * pieceLen)
        local seg = makeSegDesc(a, b, variant)
        local entity = spawnSegmentEntity(seg, alpha)
        if entity then
            local list = standData.radioNetSegments
            list[#list + 1] = entity
            entity:GetData().jjbaNetSegDesc = seg
        end
    end
end

--- Growing trail attached to a weaver while it travels.
function radioNet.updateLiveSegment(standData, liveId, from, to, alpha, variant)
    ensureSegmentLists(standData)
    alpha = alpha or standData.radioNetStampAlpha or standData.radioNetAlpha or DEFAULT_STAMP_ALPHA
    variant = variant or 1

    local length = (to - from):Length()
    if length < 2 then
        radioNet.clearLiveSegment(standData, liveId)
        return
    end

    local seg = makeSegDesc(from, to, variant)
    if length > FULL_WIDTH then
        seg.tierName = "Full"
        seg.tierWidth = FULL_WIDTH
    end

    local entry = standData.radioNetLive[liveId]
    if not entry or not entry.entity or not entry.entity:Exists() then
        local entity = spawnSegmentEntity(seg, alpha)
        if not entity then
            return
        end
        standData.radioNetLive[liveId] = { entity = entity, seg = seg, animName = animName(seg.variant, seg.tierName) }
        return
    end

    entry.seg = seg
    local sprite = entry.entity:GetSprite()
    local name = animName(seg.variant, seg.tierName)
    if entry.animName ~= name then
        sprite:Play(name, true)
        sprite.PlaybackSpeed = 0
        sprite:SetFrame(0)
        entry.animName = name
    end
    fitSegmentSprite(entry.entity, seg, alpha)
end

function radioNet.clearLiveSegment(standData, liveId)
    if not standData.radioNetLive then
        return
    end
    local entry = standData.radioNetLive[liveId]
    if entry and entry.entity and entry.entity:Exists() then
        entry.entity:Remove()
    end
    standData.radioNetLive[liveId] = nil
end

function radioNet.clearAllLive(standData)
    if not standData.radioNetLive then
        return
    end
    for liveId, _ in pairs(standData.radioNetLive) do
        radioNet.clearLiveSegment(standData, liveId)
    end
end

--- Ghost strand: grows over a few frames with no Hierophant sprite.
function radioNet.startGhost(standData, from, to, variant, growFrames)
    ensureSegmentLists(standData)
    local length = (to - from):Length()
    if length < 1 then
        return
    end

    standData.radioNetGhostId = (standData.radioNetGhostId or 0) + 1
    local id = standData.radioNetGhostId
    local liveId = "ghost_" .. tostring(id)
    standData.radioNetGhosts[id] = {
        from = Vector(from.X, from.Y),
        to = Vector(to.X, to.Y),
        variant = variant or (1 + Random() % VARIANT_COUNT),
        age = 0,
        growFrames = math.max(1, growFrames or 3),
        liveId = liveId,
    }
end

function radioNet.updateGhosts(standData)
    if not standData.radioNetGhosts then
        return
    end

    local stamp = standData.radioNetStampAlpha or DEFAULT_STAMP_ALPHA
    local finished = {}

    for id, ghost in pairs(standData.radioNetGhosts) do
        ghost.age = ghost.age + 1
        local t = math.min(1, ghost.age / ghost.growFrames)
        t = t * t * (3 - 2 * t)
        local tip = Vector(
            ghost.from.X + (ghost.to.X - ghost.from.X) * t,
            ghost.from.Y + (ghost.to.Y - ghost.from.Y) * t
        )
        radioNet.updateLiveSegment(standData, ghost.liveId, ghost.from, tip, stamp, ghost.variant)

        if ghost.age >= ghost.growFrames then
            radioNet.clearLiveSegment(standData, ghost.liveId)
            radioNet.addSegment(standData, ghost.from, ghost.to, stamp, ghost.variant)
            finished[#finished + 1] = id
        end
    end

    for _, id in ipairs(finished) do
        standData.radioNetGhosts[id] = nil
    end
end

function radioNet.countGhosts(standData)
    if not standData.radioNetGhosts then
        return 0
    end
    local n = 0
    for _ in pairs(standData.radioNetGhosts) do
        n = n + 1
    end
    return n
end

function radioNet.setAlpha(standData, alpha)
    standData.radioNetAlpha = alpha
    if standData.radioNetSegments then
        for _, entity in ipairs(standData.radioNetSegments) do
            if entity and entity:Exists() then
                local seg = entity:GetData().jjbaNetSegDesc
                if seg then
                    fitSegmentSprite(entity, seg, alpha)
                else
                    local sprite = entity:GetSprite()
                    sprite.Color = Color(1, 1, 1, alpha)
                end
            end
        end
    end
    if standData.radioNetLive then
        for _, entry in pairs(standData.radioNetLive) do
            if entry.entity and entry.entity:Exists() and entry.seg then
                fitSegmentSprite(entry.entity, entry.seg, alpha)
            end
        end
    end
end

function radioNet.pulse(standData, alpha, elapsed)
    if not standData.radioNetSegments then
        return
    end
    for i, entity in ipairs(standData.radioNetSegments) do
        if entity and entity:Exists() then
            local pulse = 0.88 + 0.12 * math.sin((elapsed or entity.FrameCount) * 0.35 + i)
            local seg = entity:GetData().jjbaNetSegDesc
            if seg then
                fitSegmentSprite(entity, seg, alpha * pulse)
            end
        end
    end
end

return radioNet
