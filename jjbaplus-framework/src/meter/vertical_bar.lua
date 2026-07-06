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

local function resolveOverlayDivisions(divisions)
    if not divisions or divisions <= 0 then
        return nil
    end

    divisions = math.floor(divisions)
    local supported = Constants.BAR_OVERLAY_DIVISIONS

    for _, count in ipairs(supported) do
        if count == divisions then
            return count
        end
    end

    local best = supported[1]
    for _, count in ipairs(supported) do
        if math.abs(count - divisions) < math.abs(best - divisions) then
            best = count
        end
    end

    return best
end

local function renderOverlay(position, large, divisions)
    local overlayDivisions = resolveOverlayDivisions(divisions)
    if not overlayDivisions then
        return
    end

    local bar = Sprites.getVerticalBar(large)
    bar:SetFrame("BarOverlay" .. overlayDivisions, 0)
    bar:Render(position, Vector(0, 0), Vector(0, 0))
end

local function renderFill(position, charge, maxCharge, large, fillColor, divisions)
    if maxCharge <= 0 then
        return
    end

    local empty = Sprites.getVerticalBar(large)
    empty:SetFrame("BarEmpty", 0)
    empty:Render(position, Vector(0, 0), Vector(0, 0))

    if charge > 0 then
        local fill = Sprites.getVerticalBarFill(large)
        fill:SetFrame("BarFull", 0)
        fill.Color = fillColor or Constants.DEFAULT_CHARGE_COLOR
        fill:Render(position, getTopLeftClamp(charge, maxCharge, large), Vector(0, 0))
        fill.Color = Constants.SPRITE_COLOR_WHITE
    end

    renderOverlay(position, large, divisions)
end

return {
    render = renderFill,
}
