local Settings = require("src/constants/settings")
local utils = require("src/utils")

return function(jsf)
    local function ForEachPlayer(player, index)
        local standDef = jsf:GetActiveStand(player)
        if not standDef then
            return
        end

        local jsfData = jsf:GetPlayerData(player)

        if not jsfData.standEntity or not jsfData.standEntity:Exists() then
            jsfData.standEntity = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, standDef.familiarVariant, 0, player.Position, Vector(0, 0), player)
            jsfData.standEntity.Parent = player
        end

        local standData = jsfData.standEntity:GetData()
        local standSprite = jsfData.standEntity:GetSprite()

        standData.alphagoal = -2.5
        standData.alpha = -2.5
        standData.posrate = 1
        if standData.behavior ~= nil then
            standData.behavior = 'idle'
        end
        standSprite.Color = Color(1, 1, 1, -2.5, 0, 0, 0)
        player:GetData().usedBoxOfFriends = false
    end

    return function()
        utils:ForAllPlayers(ForEachPlayer)
    end
end
