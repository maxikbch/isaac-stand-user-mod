local Settings = require("src/constants/settings")

return function(jsf)
    local function ChargePoints(sourceType)
        if sourceType == EntityType.ENTITY_BOMB then return 4 end
        return 1
    end

    local function ChargeStandMeter(entity, source, sourceType)
        if source and source:Exists() and Settings.HasSuper and entity:IsVulnerableEnemy() then
            if source.Type == EntityType.ENTITY_PLAYER then
                local player = source:ToPlayer()
                if not player then return end

                local standDef = jsf:GetActiveStand(player)
                if not standDef then return end

                local jsfData = jsf:GetPlayerData(player)
                local standState = jsfData.standState

                if jsfData.activeDiscItem == standDef.discItem then
                    if not standState.SuperCharge then standState.SuperCharge = 0 end

                    local STATS = standDef.stats
                    if standState.SuperCharge < STATS.SuperMaxCharge then
                        standState.SuperCharge = math.min(STATS.SuperMaxCharge, standState.SuperCharge + ChargePoints(sourceType))
                    end
                end
            elseif source.SpawnerEntity then
                ChargeStandMeter(entity, source.SpawnerEntity, sourceType)
            elseif source.Type == EntityType.ENTITY_FAMILIAR then
                local familiar = source:ToFamiliar()
                local player = familiar and familiar.Player
                ChargeStandMeter(entity, player, sourceType)
            end
        end
    end

    return function(entity, damageAmount, damageFlags, source, countdownFrames)
        ChargeStandMeter(entity, source.Entity, source.Type)
    end
end
