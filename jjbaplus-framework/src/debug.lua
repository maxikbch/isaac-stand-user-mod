local settings = require("settings")

local debug = {
    _last = {},
    _lines = {},
    _maxLines = 8,
}

function debug:Log(message)
    local text = "[JSF] " .. tostring(message)
    Isaac.DebugString(text)

    if settings.DebugOverlay then
        table.insert(self._lines, text)
        while #self._lines > self._maxLines do
            table.remove(self._lines, 1)
        end
    end
end

function debug:LogEvery(interval, key, message)
    local frame = Game():GetFrameCount()
    if not self._last[key] or frame - self._last[key] >= interval then
        self._last[key] = frame
        self:Log(tostring(message))
    end
end

function debug:Render()
    if not settings.DebugOverlay or #self._lines == 0 then
        return
    end

    local y = 40
    for _, line in ipairs(self._lines) do
        Isaac.RenderText(line, 40, y, 1, 1, 1, 1)
        y = y + 10
    end
end

return debug
