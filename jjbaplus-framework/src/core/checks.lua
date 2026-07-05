local standChecks = {}

function standChecks:IsTargetable(en, player, standEntity)
    local standData = standEntity:GetData()

    if en and not en.CollisionClass and en:Exists() and standData.TargetEntity then
        if en.Type == EntityType.ENTITY_BOMB then
            return true
        end
    end
    return false
end

function standChecks:CanPush(en, player, standEntity)
    return en
        and not en.CollisionClass
        and en.Type == EntityType.ENTITY_BOMB and not en:GetSprite():IsPlaying("Explode")
end

function standChecks:IsValidEnemy(en, player, standEntity)
    local standData = standEntity:GetData()

    return en
        and standData.TargetEntity
        and not en.CollisionClass
        and (((en:IsVulnerableEnemy() and en.HitPoints > 0) or standChecks:CanPush(en, player, standEntity))
        and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
end

function standChecks:IsValidGridEntity(position, player, standEntity)
    local room = Game():GetRoom()
    local gridEntity = room:GetGridEntityFromPos(position)
    local standData = standEntity:GetData()

    if gridEntity
        and room:GetGridIndex(position) ~= room:GetGridIndex(player.Position)
        and standData.TargetGrid
    then
        local type = gridEntity:GetType()

        if type == GridEntityType.GRID_FIREPLACE
            or type == GridEntityType.GRID_TNT
            or (type == GridEntityType.GRID_POOP and gridEntity.State and gridEntity.State < 1000)
        then
            return gridEntity
        end
    end

    return nil
end

return standChecks
