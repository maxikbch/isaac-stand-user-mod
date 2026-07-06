local JSF = _G.JoJoStandFramework
if not JSF then
    Isaac.DebugString("[JJBA+ UI Debug] Requires JJBA+ Framework mod!")
    return
end

local mod = RegisterMod("Maxo13:JJBAPlus_UI_Debug", 1)

JSF:RegisterStand(require("ui_debug.stand_definition"))

local registerCharacterCallbacks = require("ui_debug.character_callbacks")
local debugUi = require("debug_ui")
registerCharacterCallbacks(mod, debugUi)
