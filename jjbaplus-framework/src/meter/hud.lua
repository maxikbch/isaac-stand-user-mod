local Constants = require("src/meter/constants")
local RenderVerticalBar = require("src/meter/vertical_bar")
local RenderCircularMeter = require("src/meter/circular_meter")
local RenderButtonGlyph = require("src/meter/button_glyph")
local RenderStandHead = require("src/meter/stand_head")

local function getChargeValue(standState, pool)
    if pool == "super" then
        return standState.SuperCharge or 0
    end
    if pool == "alt" then
        return standState.AltCharge or 0
    end
    return 0
end

local function getMaxCharge(stats, pool)
    if pool == "super" then
        return stats.SuperMaxCharge or 0
    end
    if pool == "alt" then
        return stats.AltMaxCharge or 0
    end
    return 0
end

local function renderChargeBars(anchor, standState, stats, abilities)
    local charges = abilities.charges or {}
    local hasSuper = charges.super == true
    local hasAlt = charges.alt == true

    if not hasSuper and not hasAlt then
        return
    end

    local barPos = anchor + Constants.CHARGE_BAR

    if hasSuper and hasAlt then
        RenderVerticalBar.render(
            barPos,
            getChargeValue(standState, "super"),
            getMaxCharge(stats, "super"),
            false
        )
        RenderVerticalBar.render(
            barPos + Vector(0, Constants.CHARGE_BAR_SPACING),
            getChargeValue(standState, "alt"),
            getMaxCharge(stats, "alt"),
            false
        )
    elseif hasSuper then
        RenderVerticalBar.render(
            barPos,
            getChargeValue(standState, "super"),
            getMaxCharge(stats, "super"),
            true
        )
    elseif hasAlt then
        RenderVerticalBar.render(
            barPos,
            getChargeValue(standState, "alt"),
            getMaxCharge(stats, "alt"),
            true
        )
    end
end

local function renderAbilitySlot(anchor, frame, player, standState, stats, abilityDef, bindingName)
    if not abilityDef or not abilityDef.enabled then
        return
    end

    local slotPos = anchor + Constants.ABILITY_COLUMN
    local requiresCharge = abilityDef.requiresCharge ~= false
    local useCost = abilityDef.useCost or stats.SuperMaxCharge or 0
    local charge = getChargeValue(standState, abilityDef.chargePool or "super")
    local duration = 0
    local maxDuration = stats.SuperDuration or 0

    if bindingName == "SUPER" then
        duration = standState.SuperDuration or 0
    elseif bindingName == "ALT" then
        duration = standState.AltDuration or 0
        maxDuration = stats.AltDuration or maxDuration
    end

    local glyphCenter = Vector(16, 8)
    if requiresCharge then
        local meterCenter = RenderCircularMeter.render(
            slotPos,
            charge,
            useCost,
            duration,
            maxDuration,
            frame
        )
        if meterCenter then
            glyphCenter = meterCenter
        end
    end

    RenderButtonGlyph.render(
        slotPos + glyphCenter,
        player.ControllerIndex,
        bindingName
    )
end

return function(frame, anchor, player, standState, stats, abilities, meterGfx)
    local root = anchor + Constants.HUD_ORIGIN

    renderChargeBars(root, standState, stats, abilities)

    local headPos = root + Constants.STAND_HEAD
    RenderStandHead(headPos, standState, meterGfx)

    renderAbilitySlot(
        root,
        frame,
        player,
        standState,
        stats,
        abilities.super,
        "SUPER"
    )
    renderAbilitySlot(
        root + Vector(0, Constants.ABILITY_SLOT_SPACING),
        frame,
        player,
        standState,
        stats,
        abilities.alt,
        "ALT"
    )
end
