local LocalControllers = require("src/core/local_controllers")
local utils = require("src/utils")

return function(mod, jsf, data)
    return function(isContinuedGame)
        LocalControllers:Reset()
        data:OnGameStarted(isContinuedGame, mod)

        if not isContinuedGame then
            utils:ForAllPlayers(function(player)
                data:ResetPlayerSession(jsf, player)
            end)
        else
            utils:ForAllPlayers(function(player)
                local playerIndex = utils:GetPlayerIndex(player)
                data:LoadPlayer(mod, jsf, player, playerIndex)
            end)
        end
    end
end
