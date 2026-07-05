local character = require("character_definition")
local settings = require("settings")

local JSF = _G.JoJoStandFramework

local function mergeCharacterData(player)
    local characterData = {
        DamageMult = character.DamageMult,
        Damage = character.Damage,
        Speed = character.Speed,
        Range = character.Range,
    }

    if player:GetPlayerType() == character.Type2 then
        characterData.DamageMult = character.Tainted.DamageMult
        characterData.Damage = character.Tainted.Damage
        characterData.Speed = character.Tainted.Speed
        characterData.Range = character.Tainted.Range
    end

    return characterData
end

local function isStandUser(player)
    local playerType = player:GetPlayerType()
    return playerType == character.Type or playerType == character.Type2
end

return function(mod)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if not isStandUser(player) then
            return
        end

        local characterData = mergeCharacterData(player)

        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = (player.Damage * characterData.DamageMult) + characterData.Damage
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
                player.Damage = player.Damage * 0.75
            end
        elseif flag == CacheFlag.CACHE_RANGE then
            player.TearHeight = math.min(-7.5, player.TearHeight - characterData.Range)
        elseif flag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + characterData.Speed
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
        if not isStandUser(player) then
            return
        end

        JSF:EnsureLinkedStandDisc(player)
        player:EvaluateItems()
        player:AddNullCostume(character.Costume1)
    end)

    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        if not settings.ReapplyCostume then
            return
        end

        local config = Isaac.GetItemConfig()
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if not player or not player:Exists() then
            elseif player:GetPlayerType() == character.Type then
                player:AddNullCostume(character.Costume1)
            elseif player:GetPlayerType() == character.Type2 then
                player:AddNullCostume(character.Costume2)
                local meat = config:GetCollectible(CollectibleType.COLLECTIBLE_MEAT)
                player:AddCostume(meat, false)
            end
        end
    end)
end
