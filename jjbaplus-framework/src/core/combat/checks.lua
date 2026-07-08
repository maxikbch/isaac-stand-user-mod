local DEFAULT_GRID_TYPES = {
    [GridEntityType.GRID_FIREPLACE] = true,
    [GridEntityType.GRID_TNT] = true,
    [GridEntityType.GRID_POOP] = true,
}

local standChecks = {}

local function getPolicy(standDef)
    return (standDef and standDef.targeting) or {}
end

local function listContains(list, value)
    if not list then
        return false
    end
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

local function isAllowedGridType(gridType, policy)
    if policy.gridTypes then
        return listContains(policy.gridTypes, gridType)
    end
    return DEFAULT_GRID_TYPES[gridType] == true
end

function standChecks:IsTargetable(en, player, standDef, standEntity)
    if not en or not en:Exists() or en.CollisionClass then
        return false
    end

    local policy = getPolicy(standDef)
    if policy.entities == false then
        return false
    end

    local standData = standEntity and standEntity:GetData()
    if standData and standData.TargetEntity == false then
        return false
    end

    if policy.targetBombs ~= false and en.Type == EntityType.ENTITY_BOMB then
        return true
    end

    if listContains(policy.entityTypes, en.Type) then
        return true
    end

    return false
end

function standChecks:CanPush(en, player, standDef, standEntity)
    local policy = getPolicy(standDef)
    if policy.pushBombs == false then
        return false
    end

    return en
        and not en.CollisionClass
        and en.Type == EntityType.ENTITY_BOMB
        and not en:GetSprite():IsPlaying("Explode")
end

function standChecks:IsValidEnemy(en, player, standDef, standEntity)
    if not en or en.CollisionClass then
        return false
    end

    local policy = getPolicy(standDef)
    if policy.entities == false then
        return false
    end

    local standData = standEntity and standEntity:GetData()
    if standData and standData.TargetEntity == false then
        return false
    end

    if en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
        return false
    end

    local allowEnemy = policy.enemies ~= false
        and en:IsVulnerableEnemy()
        and en.HitPoints > 0

    local allowPush = standChecks:CanPush(en, player, standDef, standEntity)

    return allowEnemy or allowPush
end

function standChecks:IsValidGridEntity(position, player, standDef, standEntity)
    local room = Game():GetRoom()
    local gridEntity = room:GetGridEntityFromPos(position)
    local policy = getPolicy(standDef)

    if policy.grid == false then
        return nil
    end

    local standData = standEntity and standEntity:GetData()
    if standData and standData.TargetGrid == false then
        return nil
    end

    if not gridEntity then
        return nil
    end

    if room:GetGridIndex(position) == room:GetGridIndex(player.Position) then
        return nil
    end

    local gridType = gridEntity:GetType()
    if not isAllowedGridType(gridType, policy) then
        return nil
    end

    if gridType == GridEntityType.GRID_POOP and gridEntity.State and gridEntity.State >= 1000 then
        return nil
    end

    if gridType == GridEntityType.GRID_FIREPLACE and gridEntity.State and gridEntity.State >= 1000 then
        return nil
    end

    return gridEntity
end

return standChecks
