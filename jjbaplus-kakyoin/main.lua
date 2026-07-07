local JSF = _G.JoJoStandFramework
if not JSF then
    Isaac.DebugString("[JJBA+ Kakyoin] Requires JJBA+ Framework mod!")
    return
end

local mod = RegisterMod("Maxo13:JJBAPlus_Kakyoin", 1)

JSF:RegisterStand(require("kakyoin.stand_definition"))

local registerCharacterCallbacks = require("kakyoin.character_callbacks")
registerCharacterCallbacks(mod)

local emeraldEntities = require("kakyoin.emerald_entities")
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    emeraldEntities.init()
end)
