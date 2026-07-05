local JSF = _G.JoJoStandFramework
if not JSF then
    Isaac.DebugString("[JJBA+ Jotaro] Requires JJBA+ Framework mod!")
    return
end

local mod = RegisterMod("Maxo13:JJBAPlus_Jotaro", 1)

JSF:RegisterStand(require("stand_definition"))

local registerCharacterCallbacks = require("character_callbacks")
registerCharacterCallbacks(mod)
