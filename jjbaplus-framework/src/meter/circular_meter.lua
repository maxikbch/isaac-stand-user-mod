local Sprites = require("src/meter/sprites")
local Constants = require("src/meter/constants")

local CHARGING_FRAMES = 101

local function render(position, charge, maxCharge, duration, maxDuration, frame)
    local sprite = Sprites.getCircularBar()
    local scale = Constants.CIRCULAR_SCALE
    local center = Vector(16 * scale, 16 * scale)

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

    sprite.Scale = Vector(scale, scale)
    sprite:Render(position, Vector(0, 0), Vector(0, 0))
    sprite.Scale = Vector(1, 1)

    if not Game():IsPaused() then
        sprite:Update()
    end

    return center
end

return {
    render = render,
}
