local Settings = require("src/constants/settings")
local SkillState = require("src/skills/state")

local MAX_SOURCE_DEPTH = 6

local function ChargePoints(sourceType)
    if sourceType == EntityType.ENTITY_BOMB then
        return 4
    end
    return 1
end

local function ResolvePlayerFromEntity(entity, depth)
    if not entity or not entity:Exists() or depth > MAX_SOURCE_DEPTH then
        return nil
    end

    if entity.Type == EntityType.ENTITY_PLAYER then
        return entity:ToPlayer()
    end

    if entity.Type == EntityType.ENTITY_FAMILIAR then
        local familiar = entity:ToFamiliar()
        if familiar and familiar.Player then
            return familiar.Player
        end
    end

    if entity.SpawnerEntity then
        local player = ResolvePlayerFromEntity(entity.SpawnerEntity, depth + 1)
        if player then
            return player
        end
    end

    if entity.Parent then
        local player = ResolvePlayerFromEntity(entity.Parent, depth + 1)
        if player then
            return player
        end
    end

    return nil
end

local function ResolvePlayerFromDamageSource(source)
    if type(source) == "number" or source == nil then
        return nil
    end

    if source.Entity then
        local player = ResolvePlayerFromEntity(source.Entity, 0)
        if player then
            return player
        end
    end

    return nil
end

local function GetSourceType(source)
    if source and source.Type then
        return source.Type
    end
    if source and source.Entity then
        return source.Entity.Type
    end
    return EntityType.ENTITY_NULL
end

return function(jsf)
    local function ApplyStandMeterCharge(player, entity, sourceType)
        if not player or not player:Exists() then
            return
        end
        if not Settings.HasChargeMeter or not entity:IsVulnerableEnemy() then
            return
        end

        local standDef = jsf:GetActiveStand(player)
        if not standDef or not player:HasCollectible(standDef.discItem) then
            return
        end

        local jsfData = jsf:GetPlayerData(player)
        jsfData.activeDiscItem = standDef.discItem

        local standState = jsfData.standState or {}
        jsfData.standState = standState
        SkillState.ensurePools(standState, standDef.chargePools)

        local points = ChargePoints(sourceType)
        for poolId, poolDef in pairs(standDef.chargePools or {}) do
            if poolDef.gainOnHit then
                SkillState.addCharge(standState, poolId, points, poolDef.maxCharge or 0)
            end
        end
    end

    return function(_, entity, damageAmount, damageFlags, source, countdownFrames)
        local player = ResolvePlayerFromDamageSource(source)
        if player then
            ApplyStandMeterCharge(player, entity, GetSourceType(source))
        end
    end
end
