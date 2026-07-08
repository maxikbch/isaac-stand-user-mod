local utils = require("src/utils")
local debug = require("src/debug")

local function ensurePlayerData(player)
    local playerData = player:GetData()

    if not playerData.JSF then
        playerData.JSF = {
            activeStandId = nil,
            activeDiscItem = nil,
            standEntity = nil,
            standState = {},
        }
    end

    if not playerData.JSF.standState then
        playerData.JSF.standState = {}
    end

    if not playerData.JSF.input then
        playerData.JSF.input = {
            shoot = false,
            shootpress = false,
            shootrelease = false,
            releasedir = Vector(0, 0),
        }
    end

    return playerData.JSF
end

return function(registry)
    local api = {}

    function api:GetPlayerData(player)
        return ensurePlayerData(player)
    end

    function api:GetStand(id)
        return registry.stands[id]
    end

    function api:GetStandIdForDisc(discItem)
        return registry.discToStand[discItem]
    end

    function api:IsRegisteredDisc(collectibleId)
        return registry.discToStand[collectibleId] ~= nil
    end

    function api:GetActiveStandId(player)
        local jsf = ensurePlayerData(player)

        if jsf.activeStandId and registry.stands[jsf.activeStandId] then
            local cachedDef = registry.stands[jsf.activeStandId]
            if player:HasCollectible(cachedDef.discItem) then
                jsf.activeDiscItem = cachedDef.discItem
                return jsf.activeStandId
            end
        end

        for discItem, standId in pairs(registry.discToStand) do
            if player:HasCollectible(discItem) then
                jsf.activeStandId = standId
                jsf.activeDiscItem = discItem
                debug:LogEvery(60, "activeStandResolved", string.format(
                    "GetActiveStandId resolved=%s disc=%s playerType=%s",
                    standId,
                    tostring(discItem),
                    tostring(player:GetPlayerType())
                ))
                return standId
            end
        end

        debug:LogEvery(60, "activeStandMissing", string.format(
            "GetActiveStandId nil playerType=%s hasDisc=%s",
            tostring(player:GetPlayerType()),
            tostring(jsf.activeDiscItem)
        ))
        return nil
    end

    function api:GetActiveStand(player)
        local standId = self:GetActiveStandId(player)
        if standId then
            return registry.stands[standId]
        end
        return nil
    end

    function api:GetStandForCharacter(playerType)
        return registry.characterToStand[playerType]
    end

    function api:SetActiveStand(player, standId)
        local standDef = registry.stands[standId]
        if not standDef then
            return false
        end

        local jsf = ensurePlayerData(player)
        jsf.activeStandId = standId
        jsf.activeDiscItem = standDef.discItem
        jsf.standState = jsf.standState or {}

        if not player:HasCollectible(standDef.discItem) then
            player:AddCollectible(standDef.discItem, 0, false)
        end

        return true
    end

    function api:SwapStandDisc(player, newDiscItem)
        local newStandId = registry.discToStand[newDiscItem]
        if not newStandId then
            return false
        end

        local jsf = ensurePlayerData(player)
        local oldDisc = jsf.activeDiscItem

        if oldDisc and oldDisc ~= newDiscItem and player:HasCollectible(oldDisc) then
            player:RemoveCollectible(oldDisc)
            local pedestal = utils:findClosestEmptyPedestal(player)
            if pedestal then
                local pickup = pedestal:ToPickup()
                if pickup then
                    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, oldDisc, true, false, false)
                end
            else
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, oldDisc, player.Position, Vector(0, 0), nil)
            end
        end

        jsf.activeDiscItem = newDiscItem
        jsf.activeStandId = newStandId
        return true
    end

    function api:EnsureLinkedStandDisc(player)
        local playerType = player:GetPlayerType()
        local standId = registry.characterToStand[playerType]

        if not standId then
            debug:Log(string.format(
                "EnsureLinkedStandDisc skip playerType=%s (not linked)",
                tostring(playerType)
            ))
            return
        end

        local standDef = registry.stands[standId]
        if not standDef then
            debug:Log("EnsureLinkedStandDisc missing standDef for " .. tostring(standId))
            return
        end

        local hadDisc = player:HasCollectible(standDef.discItem)
        if not hadDisc then
            player:AddCollectible(standDef.discItem, 0, false)
        end

        local jsf = ensurePlayerData(player)
        jsf.activeStandId = standId
        jsf.activeDiscItem = standDef.discItem

        debug:Log(string.format(
            "EnsureLinkedStandDisc ok stand=%s disc=%s hadDisc=%s nowHas=%s",
            standId,
            tostring(standDef.discItem),
            tostring(hadDisc),
            tostring(player:HasCollectible(standDef.discItem))
        ))
    end

    function api:GetAllStandDefs()
        local defs = {}
        for _, def in pairs(registry.stands) do
            table.insert(defs, def)
        end
        return defs
    end

    return api
end
