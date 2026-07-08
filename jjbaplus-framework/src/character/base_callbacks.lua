local function getJSF()
    return _G.JoJoStandFramework
end

local function mergeCharacterData(character, player)
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

local function isCharacter(character, player)
    local playerType = player:GetPlayerType()
    return playerType == character.Type or playerType == character.Type2
end

local function reapplyCostumes(character)
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
end

return function(mod, opts)
    local character = opts.character
    local settings = opts.settings
    local hooks = opts.hooks or {}

    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if not isCharacter(character, player) then
            return
        end

        local characterData = mergeCharacterData(character, player)

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
        if not isCharacter(character, player) then
            return
        end

        getJSF():EnsureLinkedStandDisc(player)
        player:EvaluateItems()
        player:AddNullCostume(character.Costume1)
    end)

    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        if settings.ReapplyCostume then
            reapplyCostumes(character)
        end

        if hooks.onPostNewRoom then
            hooks.onPostNewRoom()
        end
    end)

    if hooks.onPostUpdate then
        mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
            hooks.onPostUpdate()
        end)
    end

    if hooks.onGetShaderParams then
        mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, function(_, name)
            return hooks.onGetShaderParams(name)
        end)
    end

    if hooks.onPostProjectileUpdate then
        mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, projectile)
            hooks.onPostProjectileUpdate(projectile)
        end)
    end

    if hooks.onEntityTakeDamage then
        mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, damageAmount, damageFlags, source, countdownFrames)
            return hooks.onEntityTakeDamage(entity, damageAmount, damageFlags, source, countdownFrames)
        end)
    end

    if hooks.onUseItem then
        mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemId, rng, player, flags, slot, customVarData)
            return hooks.onUseItem(itemId, rng, player, flags, slot, customVarData)
        end)
    end
end
