local Settings = require("src/constants/settings")
local debug = require("src/debug")

local StandInput = require("src/core/input")
local StandUpdate = require("src/core/update")
local SetStand = require("src/core/set")
local StandClear = require("src/core/clear")
local SkillDispatcher = require("src/skills/dispatcher")
local LocalControllers = require("src/core/local_controllers")
local utils = require("src/utils")

return function(jsf)
    local function ForEachPlayer(player, index)
        if Settings.NoShooting then
            player.FireDelay = 10
        end

        local standDef = jsf:GetActiveStand(player)
        if not standDef then
            debug:LogEvery(60, "postUpdateNoStand", "post_update skip: GetActiveStand nil for player " .. tostring(index))
            return
        end

        local jsfData = jsf:GetPlayerData(player)

        SetStand(player, standDef, jsfData)
        StandUpdate(player, standDef, jsfData)
        SkillDispatcher(player, standDef, jsfData)
    end

    local function resetStandLinks()
        for _, standDef in ipairs(jsf:GetAllStandDefs()) do
            for _, en in ipairs(Isaac.GetRoomEntities()) do
                if en.Type == EntityType.ENTITY_FAMILIAR and en.Variant == standDef.familiarVariant then
                    en:GetData().linked = false
                end
            end
        end
    end

    local function PostUpdate()
        StandInput:OnPostUpdate()
        debug:LogEvery(120, "postUpdateAlive", "post_update tick frame=" .. tostring(Game():GetFrameCount()))
        LocalControllers:Update()
        resetStandLinks()
        utils:ForAllPlayers(ForEachPlayer)
        StandClear(jsf:GetAllStandDefs())
    end

    return PostUpdate
end
