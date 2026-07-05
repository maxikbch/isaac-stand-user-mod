local Settings = require("src/constants/settings")
local RenderMeter = require("src/meter/bar")
local RenderStandHead = require("src/meter/stand_head")
local RenderButton = require("src/meter/button")
local utils = require("src/utils")
local debug = require("src/debug")

return function(jsf)
    local frame = 0

    local function Meter(playerData, screenOffset, standState, stats, meterGfx)
        RenderStandHead(screenOffset, standState, meterGfx)
        RenderMeter(frame, playerData, screenOffset, standState, stats, 1, meterGfx)
        RenderButton(frame, playerData, screenOffset, standState, stats, 3, false, meterGfx)
    end

    local function ForEachPlayer(player, index)
        if not utils:ShouldRenderStandMeter(player) then
            return
        end

        local standDef = jsf:GetActiveStand(player)
        if not standDef then return end

        local jsfData = jsf:GetPlayerData(player)
        local playerData = player:GetData()
        local screenOffset = utils:GetStandMeterScreenOffset(index)

        if Settings.HasSuper and player:HasCollectible(standDef.discItem) and jsfData.standState and screenOffset then
            Meter(playerData, screenOffset, jsfData.standState, standDef.stats, standDef.meterGfx)
        end
    end

    return function()
        utils:ForAllPlayers(ForEachPlayer)
        debug:Render()
        frame = frame + 1
    end
end
