local JSF = _G.JoJoStandFramework
if not JSF then
    Isaac.DebugString("[JJBA+ Jotaro] Requires JJBA+ Framework mod!")
    return
end

local mod = RegisterMod("Maxo13:JJBAPlus_Jotaro", 1)

JSF:RegisterStand(require("jotaro.stand_definition"))

local registerCharacterCallbacks = require("jotaro.character_callbacks")
registerCharacterCallbacks(mod)
