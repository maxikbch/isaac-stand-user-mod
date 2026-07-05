

local stand = require("src/constants/stand")

local json = require("json")
local utils = require("src/utils")

local function ForEachPlayer(mod)
    return function (player, index)
        local playerData = player:GetData()

        --On new run, reset StandCharge
        if playerData[stand.Id..".Item"] then 
            playerData[stand.Id..".Item"] = nil
            local serializedData = json.encode({})
            mod:SaveData(serializedData)
        end

    end
end

function OnNewGame(mod)
    return function (isContinuedGame)
        if not isContinuedGame then  
            utils:ForAllPlayers(ForEachPlayer(mod))
        end
    end
end

return OnNewGame