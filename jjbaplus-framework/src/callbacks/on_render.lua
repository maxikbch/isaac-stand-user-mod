local Settings = require("src/constants/settings")
local RenderHud = require("src/meter/hud")
local utils = require("src/utils")
local debug = require("src/debug")

return function(jsf)
    local frame = 0

    local function ForEachPlayer(player, index)
        if not utils:ShouldRenderStandMeter(player) then
            return
        end

        local standDef = jsf:GetActiveStand(player)
        if not standDef then
            return
        end

        local jsfData = jsf:GetPlayerData(player)
        local screenOffset = utils:GetStandMeterScreenOffset(index)

        if not Settings.HasSuper
            or not player:HasCollectible(standDef.discItem)
            or not jsfData.standState
            or not screenOffset then
            return
        end

        RenderHud(
            frame,
            screenOffset,
            player,
            jsfData.standState,
            standDef.stats,
            standDef.abilities,
            standDef.meterGfx
        )
    end

    return function()
        utils:ForAllPlayers(ForEachPlayer)
        debug:Render()
        frame = frame + 1
    end
end
