local json = require("json")
local utils = require("src/utils")

return function(mod, jsf)
    return function(isContinuedGame)
        if not isContinuedGame then
            utils:ForAllPlayers(function(player, index)
                local jsfData = jsf:GetPlayerData(player)
                jsfData.standState = {}
                jsfData.activeStandId = nil
                jsfData.activeDiscItem = nil
            end)
            mod:SaveData(json.encode({}))
        end
    end
end
