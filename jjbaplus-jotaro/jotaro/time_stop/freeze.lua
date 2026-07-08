local context = require("jotaro.time_stop.context")

local function updateTimeFreeze(player, standDef, standState)
    local JSF = _G.JoJoStandFramework
    local entities = Isaac.GetRoomEntities()

    if not player:HasCollectible(standDef.discItem) or Game():GetRoom():GetFrameCount() == 0 then
        context.setSkillDuration(player, 0, JSF)
    end

    local duration = context.getSkillDuration(player, JSF)

    if duration == 1 then
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
    elseif duration > 1 then
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
                        local randomV = Vector(0, 0)
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
    updateTimeFreeze = updateTimeFreeze,
}
