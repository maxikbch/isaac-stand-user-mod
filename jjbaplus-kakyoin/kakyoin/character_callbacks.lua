local character = require("kakyoin.character_definition")
local settings = require("kakyoin.settings")
local emeraldSplash = require("kakyoin.emerald_splash")

local JSF = _G.JoJoStandFramework

return function(mod)
    JSF.Character.registerCallbacks(mod, {
        character = character,
        settings = settings,
        hooks = {
            onPostNewRoom = function()
                for i = 0, Game():GetNumPlayers() - 1 do
                    local player = Isaac.GetPlayer(i)
                    if not player or not player:Exists() then
                    elseif player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2 then
                        local jsfData = JSF:GetPlayerData(player)
                        if jsfData and jsfData.standEntity then
                            emeraldSplash.cleanupStandState(jsfData.standEntity)
                        end
                    end
                end
            end,
        },
    })
end
