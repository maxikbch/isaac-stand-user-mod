
local stand = require("src/constants/stand")
local standItem = require("src/stand/item")
local json = require("json")
local utils = require("src/utils")

local data = {}

function data:Get(mod)
    if mod:HasData() then
        local data = mod:LoadData()
        local decodedData = json.decode(data)
        return decodedData
    else 
        return nil
    end
end

local function SavePlayerData(mod)
    return function (player, index)

        if player:HasCollectible(standItem) then

            local savedData = data:Get(mod) or {}

            local playerData = player:GetData()

            if not savedData.Players then
                savedData.Players = {}
            end

            if not savedData.Players["Player"..index] then
                savedData.Players["Player"..index] = {}
            end

            if playerData[stand.Id..".Item"] then
                savedData.Players["Player"..index][stand.Id..".Item"] = playerData[stand.Id..".Item"]
            end

            local serializedData = json.encode(savedData)
            mod:SaveData(serializedData)
            
        end

    end
end

local function LoadPlayerData(mod)
    return function (player, index)
        
        local playerData = player:GetData()
        local savedData = data:Get(mod)
        if savedData then
            if savedData.Players 
            and savedData.Players["Player"..index] 
            and savedData.Players["Player"..index][stand.Id..".Item"] then
                player:GetData()[stand.Id..".Item"] = savedData.Players["Player"..index][stand.Id..".Item"]
            end
        end

        if player:HasCollectible(standItem) and playerData.StandDisc ~= standItem then
            playerData.StandDisc = standItem
        end

    end
end

function data:SavePlayersData(mod)
    utils:ForAllPlayers(SavePlayerData(mod))
end

function data:LoadPlayersData(mod)
    utils:ForAllPlayers(LoadPlayerData(mod))
end

return data