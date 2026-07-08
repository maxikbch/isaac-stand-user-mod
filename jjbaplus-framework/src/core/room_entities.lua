local cachedFrame = -1
local cachedEntities = nil

local function Get()
    local frame = Game():GetFrameCount()
    if cachedEntities == nil or cachedFrame ~= frame then
        cachedFrame = frame
        cachedEntities = Isaac.GetRoomEntities()
    end
    return cachedEntities
end

local function Invalidate()
    cachedFrame = -1
    cachedEntities = nil
end

return {
    Get = Get,
    Invalidate = Invalidate,
}
