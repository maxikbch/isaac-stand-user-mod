local Constants = require("src/meter/constants")
local RenderVerticalBar = require("src/meter/vertical_bar")
local RenderCircularMeter = require("src/meter/circular_meter")
local RenderStandHead = require("src/meter/stand_head")
local SkillState = require("src/skills/state")
local SkillResolve = require("src/skills/resolve")

local METER_POOL_ORDER = { "primary", "secondary" }

local function getMeterPools(standDef)
    local pools = {}
    local chargePools = standDef.chargePools or {}

    for _, poolId in ipairs(METER_POOL_ORDER) do
        local poolDef = chargePools[poolId]
        if poolDef and (poolDef.maxCharge or 0) > 0 and poolDef.meter ~= false then
            pools[#pools + 1] = poolId
        end
    end

    return pools
end

local function getSlotSkillDef(standDef, slotDef, player, standState)
    if not slotDef then
        return nil, nil
    end

    local skillId = SkillResolve.resolveSkillId(slotDef, player, standDef, standState)
    if not skillId then
        return nil, nil
    end

    return skillId, standDef.skills and standDef.skills[skillId]
end

local function resolveFillColor(skillDef, poolDef)
    if skillDef and skillDef.fillColor then
        return skillDef.fillColor
    end
    if poolDef and poolDef.fillColor then
        return poolDef.fillColor
    end
    return nil
end

local function renderChargeBars(anchor, standState, standDef)
    local meterPools = getMeterPools(standDef)
    if #meterPools == 0 then
        return
    end

    local barPos = anchor + Constants.CHARGE_BAR
    local chargePools = standDef.chargePools

    for index, poolId in ipairs(meterPools) do
        local poolDef = chargePools[poolId]
        local yOffset = (index - 1) * Constants.CHARGE_BAR_SPACING
        RenderVerticalBar.render(
            barPos + Vector(0, yOffset),
            SkillState.getCharge(standState, poolId),
            poolDef.maxCharge,
            #meterPools == 1,
            poolDef.fillColor,
            poolDef.divisions
        )
    end
end

local function renderSkillSlot(anchor, yOffset, frame, player, standState, standDef, slotName, slotDef)
    if not slotDef or not slotDef.enabled then
        return
    end

    local slotPos = anchor + Constants.ABILITY_COLUMN + Vector(0, yOffset)
    local skillId, skillDef = getSlotSkillDef(standDef, slotDef, player, standState)
    local requiresCharge = slotDef.requiresCharge ~= false
    local poolId = slotDef.chargePool or (skillDef and skillDef.chargePool) or "primary"
    local poolDef = standDef.chargePools and standDef.chargePools[poolId]
    local useCost = slotDef.useCost or (skillDef and skillDef.useCost) or (poolDef and poolDef.maxCharge) or 0
    local charge = SkillState.getCharge(standState, poolId)
    local duration = skillId and SkillState.getDuration(standState, skillId) or 0
    local maxDuration = skillDef and skillDef.duration or 0

    local fillColor = resolveFillColor(skillDef, poolDef)

    if requiresCharge then
        RenderCircularMeter.render(
            slotPos,
            charge,
            useCost,
            duration,
            maxDuration,
            frame,
            slotName,
            fillColor
        )
    else
        RenderCircularMeter.render(
            slotPos,
            1,
            1,
            duration,
            maxDuration,
            frame,
            slotName,
            fillColor
        )
    end
end

return function(frame, anchor, player, standState, standDef, meterGfx)
    local root = anchor + Constants.HUD_ORIGIN
    local slots = standDef.slots or {}

    -- Ability slots first so charge bars and stand head draw on top.
    renderSkillSlot(root, 0, frame, player, standState, standDef, "skill1", slots.skill1)
    renderSkillSlot(
        root,
        Constants.ABILITY_SLOT_SPACING,
        frame,
        player,
        standState,
        standDef,
        "skill2",
        slots.skill2
    )

    renderChargeBars(root, standState, standDef)

    local headPos = root + Constants.STAND_HEAD
    RenderStandHead(headPos, standState, meterGfx)
end
