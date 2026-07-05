local JSF = _G.JoJoStandFramework
if not JSF then
    Isaac.DebugString("[JoJo Stand User] Requires JoJo Stand Framework mod!")
    return
end

local mod = RegisterMod("Maxo13:JoJoStandUser", 1)

JSF:RegisterStand(require("stand_definition"))

local registerCharacterCallbacks = require("character_callbacks")
registerCharacterCallbacks(mod)
