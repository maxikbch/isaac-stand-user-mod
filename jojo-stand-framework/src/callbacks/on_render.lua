local Settings = require("src/constants/settings")
local RenderMeter = require("src/meter/bar")
local RenderStandHead = require("src/meter/stand_head")
local RenderButton = require("src/meter/button")
local utils = require("src/utils")

local x1 = 36
local x2 = 360
local y1 = 27
local y2 = 190

local offset = {
    Player0 = Vector(x1, y1),
    Player1 = Vector(x2, y1),
    Player2 = Vector(x1, y2),
    Player3 = Vector(x2, y2),
}

return function(jsf)
    local frame = 0

    local function Meter(playerData, screenOffset, standState, stats)
        RenderStandHead(screenOffset, standState)
        RenderMeter(frame, playerData, screenOffset, standState, stats, 1)
        RenderButton(frame, playerData, screenOffset, standState, stats, 2)
    end

    local function ForEachPlayer(player, index)
        local standDef = jsf:GetActiveStand(player)
        if not standDef then return end

        local jsfData = jsf:GetPlayerData(player)
        local playerData = player:GetData()

        if Settings.HasSuper and player:HasCollectible(standDef.discItem) and jsfData.standState and offset["Player"..index] then
            Meter(playerData, offset["Player"..index], jsfData.standState, standDef.stats)
        end
    end

    return function()
        utils:ForAllPlayers(ForEachPlayer)
        frame = frame + 1
    end
end
