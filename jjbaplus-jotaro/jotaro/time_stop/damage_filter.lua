local context = require("jotaro.time_stop.context")

local function onEntityTakeDamage(entity, damageFlags, source, JSF)
    if not source or not source.Entity then
        return nil
    end

    local srcEntity = source.Entity
    if srcEntity.Type ~= EntityType.ENTITY_PLAYER then
        return nil
    end

    local player = srcEntity:ToPlayer()
    if not player then
        return nil
    end

    local _, standState = context.getStandContext(player, JSF)
    if not standState then
        return nil
    end

    if context.getSkillDuration(standState) > 0
        and entity.Type ~= EntityType.ENTITY_PLAYER
        and damageFlags & DamageFlag.DAMAGE_LASER ~= 0
        and not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        return false
    end

    return nil
end

return {
    onEntityTakeDamage = onEntityTakeDamage,
}
