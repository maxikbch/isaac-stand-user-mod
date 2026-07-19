local Settings = require("src/constants/settings")
local debug = require("src/debug")

local StandInput = require("src/core/input")
local StandUpdate = require("src/core/update")
local SetStand = require("src/core/set")
local StandClear = require("src/core/clear")
local SkillDispatcher = require("src/skills/dispatcher")
local FullChargeSounds = require("src/skills/full_charge_sounds")
local LocalControllers = require("src/core/local_controllers")
local RoomEntities = require("src/core/room_entities")
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
        FullChargeSounds.update(player, standDef, jsfData.standState)
    end

    local function collectLinkedStandHashes()
        local linkedHashes = {}
        utils:ForAllPlayers(function(player)
            local jsfData = jsf:GetPlayerData(player)
            local standEntity = jsfData and jsfData.standEntity
            if standEntity and standEntity:Exists() then
                linkedHashes[GetPtrHash(standEntity)] = true
                standEntity:GetData().linked = true
            end
        end)
        return linkedHashes
    end

    local function PostUpdate()
        StandInput:OnPostUpdate()
        debug:LogEvery(120, "postUpdateAlive", "post_update tick frame=" .. tostring(Game():GetFrameCount()))
        LocalControllers:Update()
        utils:ForAllPlayers(ForEachPlayer)

        local roomEntities = RoomEntities.Get()
        local linkedHashes = collectLinkedStandHashes()
        StandClear(jsf:GetAllStandDefs(), linkedHashes, roomEntities)
    end

    return PostUpdate
end
