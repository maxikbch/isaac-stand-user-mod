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

function standChecks:CanPush(en)
    return en
        and not en.CollisionClass
        and en.Type == EntityType.ENTITY_BOMB
        and not en:GetSprite():IsPlaying("Explode")
end

function standChecks:IsValidEnemy(en, player, standEntity)
    local standData = standEntity:GetData()

    return en
        and standData.TargetEntity
        and not en.CollisionClass
        and (((en:IsVulnerableEnemy() and en.HitPoints > 0) or standChecks:CanPush(en))
        and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
end

return standChecks
