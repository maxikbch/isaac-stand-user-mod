local Settings = require("src/constants/settings")

local StandUpdate = require("src/core/update")
local SetStand = require("src/core/set")
local StandClear = require("src/core/clear")
local StandSuper = require("src/core/super")
local utils = require("src/utils")

return function(jsf)
    local function ForEachPlayer(player, index)
        if Settings.NoShooting then
            player.FireDelay = 10
        end

        local standDef = jsf:GetActiveStand(player)
        if not standDef then
            return
        end

        local jsfData = jsf:GetPlayerData(player)

        SetStand(player, standDef, jsfData)
        StandUpdate(player, standDef, jsfData)
        StandSuper(player, standDef, jsfData)
    end

    local function PostUpdate()
        utils:ForAllPlayers(ForEachPlayer)
        StandClear(jsf:GetAllStandDefs())
    end

    return PostUpdate
end
