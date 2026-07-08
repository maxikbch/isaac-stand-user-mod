local character = require("{{ID}}.character_definition")
local settings = require("{{ID}}.settings")

local JSF = _G.JoJoStandFramework

return function(mod)
    JSF.Character.registerCallbacks(mod, {
        character = character,
        settings = settings,
    })
end
