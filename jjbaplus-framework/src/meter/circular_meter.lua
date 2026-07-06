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

local function render(position, charge, maxCharge, duration, maxDuration, frame, slotName)
    slotName = slotName or "skill1"
    local sprite = Sprites.getCircularBar(slotName)
    local scale = Constants.CIRCULAR_SCALE
    local center = Vector(16 * scale, 16 * scale)
    local renderPos = position

    if duration and duration > 0 and maxDuration and maxDuration > 0 then
        local pct = duration / maxDuration
        local chargingFrame = math.floor((1 - pct) * (CHARGING_FRAMES - 1))
        sprite:SetFrame("Charging", chargingFrame)
    elseif maxCharge > 0 and charge >= maxCharge then
        if not sprite:IsPlaying("Charged") then
            sprite:Play("Charged", true)
        end
    elseif maxCharge > 0 then
        local chargingFrame = math.floor((charge / maxCharge) * (CHARGING_FRAMES - 1))
        sprite:SetFrame("Charging", chargingFrame)
    end

    renderBg(renderPos, slotName, scale)

    sprite.Scale = Vector(scale, scale)
    sprite:RenderLayer(CHARGE_LAYER, renderPos, Vector(0, 0), Vector(0, 0))
    sprite:RenderLayer(PULSE_LAYER, renderPos, Vector(0, 0), Vector(0, 0))
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
