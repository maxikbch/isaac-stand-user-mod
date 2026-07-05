local Settings = require("src/constants/settings")
local Sprites = require("src/meter/sprites")
local Constants = require("src/meter/constants")
local input = require("src/core/input")

local BINDINGS = {
    skill1 = {
        key = function() return Settings.KEY_SKILL1 end,
        button = function() return Settings.BUTTON_SKILL1 end,
    },
    skill2 = {
        key = function() return Settings.KEY_SKILL2 end,
        button = function() return Settings.BUTTON_SKILL2 end,
    },
}

local function getGlyphFrame(controllerIndex, bindingName)
    local binding = BINDINGS[bindingName]
    if not binding then
        return nil, nil
    end

    local glyph = Constants.GLYPH
    if input:IsKeyboardController(controllerIndex) then
        return glyph.animation, glyph.keyboard[binding.key()]
    end
    return glyph.animation, glyph.controller[binding.button()]
end

local function render(position, controllerIndex, bindingName)
    local animation, frameIndex = getGlyphFrame(controllerIndex, bindingName)
    if not animation or frameIndex == nil then
        return
    end

    local sprite = Sprites.getButtons()
    sprite:SetFrame(animation, frameIndex)
    sprite:Render(position, Vector(0, 0), Vector(0, 0))
end

return {
    render = render,
}
