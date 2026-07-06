local JSF = _G.JoJoStandFramework
if not JSF then
    Isaac.DebugString("[{{DISPLAY_NAME}}] Requires JJBA+ Framework mod!")
    return
end

local mod = RegisterMod("{{REGISTER_MOD}}", 1)

JSF:RegisterStand(require("{{ID}}.stand_definition"))

local registerCharacterCallbacks = require("{{ID}}.character_callbacks")
registerCharacterCallbacks(mod)
