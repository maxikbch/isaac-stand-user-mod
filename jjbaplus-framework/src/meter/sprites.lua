local Constants = require("src/meter/constants")

local cache = {}

local function get(path, key)
    local cacheKey = key or path
    if not cache[cacheKey] then
        local sprite = Sprite()
        sprite:Load(path, true)
        cache[cacheKey] = sprite
    end
    return cache[cacheKey]
end

return {
    getVerticalBar = function(large)
        if large then
            return get(Constants.PATHS.verticalLarge, "vertical_large_empty")
        end
        return get(Constants.PATHS.verticalSmall, "vertical_small_empty")
    end,

    getVerticalBarFill = function(large)
        if large then
            return get(Constants.PATHS.verticalLarge, "vertical_large_fill")
        end
        return get(Constants.PATHS.verticalSmall, "vertical_small_fill")
    end,

    getCircularBar = function()
        return get(Constants.PATHS.circular, "circular")
    end,

    getButtons = function()
        return get(Constants.PATHS.buttons, "buttons")
    end,
}
