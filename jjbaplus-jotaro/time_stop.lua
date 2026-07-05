local STAND_ID = "star_platinum"

local randomV = Vector(0, 0)
local sfx = SFXManager()
local music = MusicManager()

local function getStandContext(player, JSF)
    local standDef = JSF:GetActiveStand(player)
    if not standDef or standDef.id ~= STAND_ID then
        return nil, nil
    end

    if not player:HasCollectible(standDef.discItem) then
        return nil, nil
    end

    local jsfData = JSF:GetPlayerData(player)
    return standDef, jsfData.standState
end

local function forEachStarPlatinumPlayer(JSF, fn)
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player and player:Exists() then
            local standDef, standState = getStandContext(player, JSF)
            if standDef and standState then
                fn(player, standDef, standState)
            end
        end
    end
end

local function updateTimeFreeze(player, standDef, standState)
    local entities = Isaac.GetRoomEntities()

    if not player:HasCollectible(standDef.discItem) or Game():GetRoom():GetFrameCount() == 0 then
        standState.SuperDuration = 0
    end

    if standState.SuperDuration == nil then
        return
    end

    if standState.SuperDuration == 1 then
        for i, entity in pairs(entities) do
            if entity:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
                entity:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
                if entity.Type == EntityType.ENTITY_TEAR then
                    local data = entity:GetData()
                    if data.TimeFrozen then
                        data.TimeFrozen = nil
                        entities[i].Velocity = data.StoredVel
                        local tear = entities[i]:ToTear()
                        tear.FallingSpeed = data.StoredFall
                        tear.FallingAcceleration = data.StoredAcc
                    end
                elseif entity.Type == EntityType.ENTITY_LASER then
                    entity:GetData().TimeFrozen = nil
                elseif entity.Type == EntityType.ENTITY_KNIFE then
                    entity:GetData().TimeFrozen = nil
                end
            end
        end
    elseif standState.SuperDuration > 1 then
        for i, entity in pairs(entities) do
            if entity.Type ~= EntityType.ENTITY_PLAYER and entity.Type ~= EntityType.ENTITY_FAMILIAR then
                if entity.Type ~= EntityType.ENTITY_PROJECTILE then
                    if not entity:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
                        entities[i]:AddEntityFlags(EntityFlag.FLAG_FREEZE)
                    end
                end

                if entity.Type == EntityType.ENTITY_TEAR then
                    local data = entity:GetData()
                    if not data.TimeFrozen then
                        if entity.Velocity.X ~= 0 or entity.Velocity.Y ~= 0
                            or not player:HasCollectible(CollectibleType.COLLECTIBLE_ANTI_GRAVITY) then
                            data.TimeFrozen = true
                            data.StoredVel = entities[i].Velocity
                            local tear = entities[i]:ToTear()
                            data.StoredFall = tear.FallingSpeed
                            data.StoredAcc = tear.FallingAcceleration
                        else
                            entities[i]:ToTear().FallingSpeed = 0
                        end
                    else
                        local tear = entities[i]:ToTear()
                        entities[i].Velocity = Vector(0, 0)
                        tear.FallingAcceleration = -0.1
                        tear.FallingSpeed = 0
                    end
                elseif entity.Type == EntityType.ENTITY_BOMB then
                    local bomb = entity:ToBomb()
                    bomb:SetExplosionCountdown(2)
                    if entity.Variant == 4 then
                        bomb.Velocity = Vector(0, 0)
                    end
                elseif entity.Type == EntityType.ENTITY_LASER then
                    if entity.Variant ~= 2 then
                        local laser = entity:ToLaser()
                        local data = entity:GetData()
                        if laser and not data.TimeFrozen and not laser:IsCircleLaser() then
                            local newLaser = player:FireBrimstone(Vector.FromAngle(laser.StartAngleDegrees))
                            newLaser.Position = laser.Position
                            newLaser.DisableFollowParent = true
                            newLaser:GetData().TimeFrozen = true
                            laser.CollisionDamage = -100
                            data.TimeFrozen = true
                            laser.DisableFollowParent = true
                            laser.Visible = false
                        end
                        laser:SetTimeout(true)
                    end
                elseif entity.Type == EntityType.ENTITY_KNIFE then
                    local data = entity:GetData()
                    local knife = entity:ToKnife()
                    if knife and knife:IsFlying() then
                        local number = 1
                        local offset = 0
                        local offset2 = 0
                        local brimDamage = 0
                        if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
                            number = math.random(math.floor(3 + knife.Charge * 3), math.floor(4 + knife.Charge * 4))
                            offset = math.random(-150, 150) / 10
                            offset2 = math.random(-300, 300) / 1000
                            brimDamage = 1.5
                        end
                        for _ = 1, number do
                            local newKnife = player:FireTear(knife.Position, Vector(0, 0), false, true, false)
                            local newData = newKnife:GetData()
                            newData.Knife = true
                            newKnife.TearFlags = 1 << 1
                            newKnife.Scale = 1
                            newKnife:ResetSpriteScale()
                            newKnife.FallingAcceleration = -0.1
                            newKnife.FallingSpeed = 0
                            newKnife.Height = -10
                            randomV.X = 0
                            randomV.Y = 1 + offset2
                            newKnife.Velocity = randomV:Rotated(knife.Rotation - 90 + offset) * 15 * player.ShotSpeed
                            newKnife.CollisionDamage = knife.Charge * player.Damage * (3 - brimDamage)
                            newKnife.GridCollisionClass = GridCollisionClass.COLLISION_NONE
                            newKnife.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                            newKnife.SpriteRotation = newKnife.Velocity:GetAngleDegrees() + 90
                            local sprite = newKnife:GetSprite()
                            sprite:ReplaceSpritesheet(0, "gfx/tearKnife.png")
                            sprite:LoadGraphics()
                            knife:Reset()
                            offset = math.random(-150, 150) / 10
                            offset2 = math.random(-300, 300) / 1000
                        end
                    end
                end
            end
        end
    else
        for _, entity in pairs(entities) do
            if entity:GetData().Knife then
                for _, other in pairs(entities) do
                    if other:IsVulnerableEnemy()
                        and not other:GetData().Knife
                        and other.Position:Distance(entity.Position) < other.Size + 7 then
                        other:TakeDamage(entity.CollisionDamage, 0, EntityRef(entity), 0)
                    end
                end
                if player.Position:Distance(entity.Position) > 1000 then
                    entity:Remove()
                end
            end
        end
    end
end

return {
    onSuperStart = function(player, standDef)
        sfx:Play(standDef.sounds.stopTime, 2, 0, false, 1)
        sfx:Play(standDef.sounds.zaWarudo, 2, 0, false, 1)
        music:Disable()
    end,

    postUpdate = function(JSF)
        forEachStarPlatinumPlayer(JSF, updateTimeFreeze)
    end,

    onShader = function(name, JSF)
        if name ~= "ZaWarudo" then
            return nil
        end

        local dist = 0
        local on = 0
        local standDef = JSF:GetStand(STAND_ID)
        if not standDef then
            return { DistortionScale = 0, DistortionOn = 0 }
        end

        local maxTime = standDef.stats.SuperDuration

        forEachStarPlatinumPlayer(JSF, function(_, _, standState)
            if standState.SuperDuration and standState.SuperDuration > 0 then
                dist = 1 / (maxTime - 2 - standState.SuperDuration)
                    + 1 / (standState.SuperDuration - 2)
                if dist < 0 then
                    dist = math.abs(dist) ^ 2
                elseif standState.SuperDuration - 2 == 0 or maxTime - 2 - standState.SuperDuration == 0 then
                    dist = 1
                else
                    on = 0.5
                end
                if standState.SuperDuration == 277 then
                    sfx:Play(standDef.sounds.tick9, 5, 0, false, 1)
                elseif standState.SuperDuration == 157 then
                    sfx:Play(standDef.sounds.tick5, 5, 0, false, 1)
                elseif standState.SuperDuration == 1 then
                    sfx:Play(standDef.sounds.resumeTime, 2, 0, false, 1)
                    music:Resume()
                elseif standState.SuperDuration == 0 then
                    dist = 0
                end
            end
        end)

        if shaderAPI then
            shaderAPI.Shader("ZaWarudo", { DistortionScale = dist, DistortionOn = on })
        else
            return { DistortionScale = dist, DistortionOn = on }
        end
    end,

    onProjectileUpdate = function(tear, JSF)
        local source = tear.SpawnerEntity
        if not source then
            return
        end

        local player = source:ToPlayer()
        if not player then
            return
        end

        local _, standState = getStandContext(player, JSF)
        if not standState then
            return
        end

        if standState.SuperDuration == 1 then
            local data = tear:GetData()
            data.TimeFrozen = false
            tear.Velocity = data.StoredVel
            tear.FallingSpeed = data.StoredFall
            tear.FallingAccel = data.StoredAcc
        elseif standState.SuperDuration > 1 then
            local data = tear:GetData()
            if not data.TimeFrozen then
                data.TimeFrozen = true
                data.StoredVel = tear.Velocity
                data.StoredFall = tear.FallingSpeed
                data.StoredAcc = tear.FallingAccel
            else
                tear.Velocity = Vector(0, 0)
                tear.FallingAccel = -0.1
                tear.FallingSpeed = 0
            end
        end
    end,

    onEntityTakeDamage = function(entity, damageFlags, source, JSF)
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

        local _, standState = getStandContext(player, JSF)
        if not standState then
            return nil
        end

        if standState.SuperDuration and standState.SuperDuration > 0
            and entity.Type ~= EntityType.ENTITY_PLAYER
            and damageFlags & DamageFlag.DAMAGE_LASER ~= 0
            and not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
            return false
        end

        return nil
    end,
}
