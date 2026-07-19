local Sprites = require("src/meter/sprites")
local Constants = require("src/meter/constants")

local CHARGING_FRAMES = 101
local CHARGE_LAYER = 1
local PULSE_LAYER = 2

local function renderBg(position, slotName, scale)
    local bgAnim = Constants.CIRCULAR_BG[slotName] or Constants.CIRCULAR_BG.skill1
    local bg = Sprites.getCircularBg(slotName)

    bg:SetFrame(bgAnim, 0)
    bg.Scale = Vector(scale, scale)
    bg:Render(position, Vector(0, 0), Vector(0, 0))
    bg.Scale = Vector(1, 1)
end

local function chargedPulseAlpha(frame)
    local wave = (math.sin(frame * Constants.CIRCULAR_CHARGED_PULSE_SPEED) + 1) * 0.5
    return (wave ^ Constants.CIRCULAR_CHARGED_PULSE_POWER) * Constants.CIRCULAR_CHARGED_PULSE_ALPHA
end

local function render(position, charge, maxCharge, duration, maxDuration, frame, slotName, fillColor)
    slotName = slotName or "skill1"
    local sprite = Sprites.getCircularBar(slotName)
    local scale = Constants.CIRCULAR_SCALE
    local center = Vector(16 * scale, 16 * scale)
    local renderPos = position
    local tint = fillColor or Constants.DEFAULT_CHARGE_COLOR
    local isActive = duration and duration > 0 and maxDuration and maxDuration > 0
    local isCharged = not isActive and maxCharge > 0 and charge >= maxCharge

    if isActive then
        local pct = duration / maxDuration
        local chargingFrame = math.floor(pct * (CHARGING_FRAMES - 1))
        sprite:SetFrame("Charging", chargingFrame)
    elseif isCharged then
        if not sprite:IsPlaying("Charged") then
            sprite:Play("Charged", true)
        end
    elseif maxCharge > 0 then
        local chargingFrame = math.floor((charge / maxCharge) * (CHARGING_FRAMES - 1))
        sprite:SetFrame("Charging", chargingFrame)
    end

    renderBg(renderPos, slotName, scale)

    sprite.Scale = Vector(scale, scale)
    sprite.Color = tint
    sprite:RenderLayer(CHARGE_LAYER, renderPos, Vector(0, 0), Vector(0, 0))
    sprite:RenderLayer(PULSE_LAYER, renderPos, Vector(0, 0), Vector(0, 0))

    if isCharged then
        local pulse = chargedPulseAlpha(frame or 0)
        if pulse > 0.01 then
            sprite.Color = Color(1, 1, 1, pulse, 0, 0, 0)
            sprite:RenderLayer(CHARGE_LAYER, renderPos, Vector(0, 0), Vector(0, 0))
        end
    end

    sprite.Color = Constants.SPRITE_COLOR_WHITE
    sprite.Scale = Vector(1, 1)

    if not Game():IsPaused() then
        sprite:Update()
    end

    return center
end

return {
    render = render,
    renderBg = function(position, slotName)
        renderBg(position, slotName or "skill1", Constants.CIRCULAR_SCALE)
    end,
}
