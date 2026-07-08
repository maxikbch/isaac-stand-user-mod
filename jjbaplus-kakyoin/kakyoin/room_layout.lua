local game = Game()

--- Expand atypical room shapes (L / thin) to feel like their full counterparts:
--- L → 2x2 square, IH/IV → 1x1 square, IIH → 2x1, IIV → 1x2.

local function getShapeName(room)
    if not room or type(room.GetRoomShape) ~= "function" or not RoomShape then
        return nil
    end

    local shape = room:GetRoomShape()
    for k, v in pairs(RoomShape) do
        if v == shape and type(k) == "string" then
            return k:upper()
        end
    end
    return nil
end

local function classifyShape(name)
    if not name then
        return "normal"
    end
    if name:find("ROOMSHAPE_L") or name:find("_L_") or name:find("_L$") or name:find("CORNER") then
        return "l"
    end
    -- Thin variants (order matters: IIH/IIV before IH/IV).
    if name:find("IIH") then
        return "thin_2x1"
    end
    if name:find("IIV") then
        return "thin_1x2"
    end
    if name:find("IH") and not name:find("IIH") then
        return "thin_1x1"
    end
    if name:find("IV") and not name:find("IIV") then
        return "thin_1x1"
    end
    return "normal"
end

local function centeredRect(center, width, height)
    local halfW = width * 0.5
    local halfH = height * 0.5
    return Vector(center.X - halfW, center.Y - halfH), Vector(center.X + halfW, center.Y + halfH)
end

--- Returns effective (topLeft, bottomRight) for overlay + rain spawn.
local function getEffectiveRoomRect()
    local room = game:GetRoom()
    local topLeft = room:GetTopLeftPos()
    local bottomRight = room:GetBottomRightPos()
    local size = bottomRight - topLeft
    local center = (topLeft + bottomRight) * 0.5
    local kind = classifyShape(getShapeName(room))

    if kind == "normal" then
        return topLeft, bottomRight
    end

    if kind == "l" or kind == "thin_1x1" then
        -- L → 2x2; thin 1x1 (IH/IV) → normal 1x1 square.
        local side = math.max(size.X, size.Y)
        return centeredRect(center, side, side)
    end

    if kind == "thin_2x1" then
        -- IIH: keep full 2x1 width, expand height like a normal 2x1 (~half of width if square tiles).
        local width = math.max(size.X, size.Y)
        local height = math.max(size.Y, width * 0.5)
        return centeredRect(center, width, height)
    end

    if kind == "thin_1x2" then
        -- IIV: keep full 1x2 height, expand width like a normal 1x2.
        local height = math.max(size.X, size.Y)
        local width = math.max(size.X, height * 0.5)
        return centeredRect(center, width, height)
    end

    return topLeft, bottomRight
end

return {
    getEffectiveRoomRect = getEffectiveRoomRect,
}
