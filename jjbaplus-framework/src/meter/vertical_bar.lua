local Sprites = require("src/meter/sprites")
local Constants = require("src/meter/constants")

-- Same approach as vanilla / IsaacScript: render BarFull at the same position as
-- BarEmpty and crop from the top with TopLeftClamp (no Scale — avoids pivot drift).
local function getTopLeftClamp(charge, maxCharge, large)
    local cfg = large and Constants.CHARGE_BAR_FILL.large or Constants.CHARGE_BAR_FILL.small
    local meterMultiplier = cfg.fillHeight / maxCharge
    local meterClip = cfg.clipEmpty - charge * meterMultiplier
    local clipFull = cfg.clipEmpty - cfg.fillHeight
    return Vector(0, math.max(clipFull, meterClip))
end

local function renderFill(position, charge, maxCharge, large)
    if maxCharge <= 0 then
        return
    end

    local empty = Sprites.getVerticalBar(large)
    empty:SetFrame("BarEmpty", 0)
    empty:Render(position, Vector(0, 0), Vector(0, 0))

    if charge <= 0 then
        return
    end

    local fill = Sprites.getVerticalBarFill(large)
    fill:SetFrame("BarFull", 0)
    fill:Render(position, getTopLeftClamp(charge, maxCharge, large), Vector(0, 0))
end

return {
    render = renderFill,
}
