local stand = require("src/constants/stand")
local STATS = require("src/constants/stats")
local Settings = require("src/constants/settings")
local standItem = require("src/stand/item")
local sfx = SFXManager()
local music = MusicManager()
local sounds = require("src/constants/sounds")

local function DoSuper(player, standEntity)
  local playerData = player:GetData()
  local standItemData = playerData[stand.Id .. ".Item"]
  sfx:Play(sounds.stopTime, 2, 0, false, 1)
	sfx:Play(sounds.zaWarudo, 2, 0, false, 1)
  --stand.savedTime = Game().TimeCounter
  music:Disable()
  standItemData.SuperDuration = STATS.SuperDuration
  standItemData.SuperCharge = 0
end

local function FinishSuper(player, standEntity)
  local playerData = player:GetData()
  local standItemData = playerData[stand.Id .. ".Item"]

  standItemData.SuperCooldown = STATS.SuperCooldown
end

local function UpdateSuper(player, standEntity)
  local playerData = player:GetData()
  local standItemData = playerData[stand.Id .. ".Item"] or {}

  if (standItemData.SuperCooldown or 0) > 0 then
    standItemData.SuperCooldown = math.max(0, standItemData.SuperCooldown - 1)
  end

  if (standItemData.SuperDuration or 0) > 0 then
    standItemData.SuperDuration = math.max(0, standItemData.SuperDuration - 1)
    if standItemData.SuperDuration == 0 then
      FinishSuper(player, stand)
    end
  end
end

local function UpdateTimeFreeze(player, standItemData)
  local entities = Isaac.GetRoomEntities()

  if not player:HasCollectible(standItem) or Game():GetRoom():GetFrameCount() == 0 then
    standItemData.SuperDuration = 0
  end

  if standItemData.SuperDuration == nil then return end

  if standItemData.SuperDuration == 1 then
    for i, v in pairs(entities) do
      if v:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
        v:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
        if v.Type == EntityType.ENTITY_TEAR then
          local data = v:GetData()
          if data.TimeFrozen then
            data.TimeFrozen = nil
            local tear = v:ToTear()
            entities[i].Velocity = data.StoredVel
            tear = entities[i]:ToTear()
            tear.FallingSpeed = data.StoredFall
            tear.FallingAcceleration = data.StoredAcc
          end
        elseif v.Type == EntityType.ENTITY_LASER then
          local data = v:GetData()
          data.TimeFrozen = nil
        elseif v.Type == EntityType.ENTITY_KNIFE then
          local data = v:GetData()
          data.TimeFrozen = nil
        end
      end
    end
  elseif standItemData.SuperDuration > 1 then
    --Game().TimeCounter = stand.savedTime
    for i, v in pairs(entities) do
      if entities[i].Type ~= EntityType.ENTITY_PLAYER and entities[i].Type ~= EntityType.ENTITY_FAMILIAR then
        if entities[i].Type ~= EntityType.ENTITY_PROJECTILE then
          if not v:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
            entities[i]:AddEntityFlags(EntityFlag.FLAG_FREEZE)
          end
        end
        if entities[i].Type == EntityType.ENTITY_TEAR then
          local data = v:GetData()
          if not data.TimeFrozen then
            if v.Velocity.X ~= 0 or v.Velocity.Y ~= 0 or not player:HasCollectible(CollectibleType.COLLECTIBLE_ANTI_GRAVITY) then
              data.TimeFrozen = true
              data.StoredVel = entities[i].Velocity
              local tear = entities[i]:ToTear()
              ---@diagnostic disable-next-line: need-check-nil
              data.StoredFall = tear.FallingSpeed
              ---@diagnostic disable-next-line: need-check-nil
              data.StoredAcc = tear.FallingAcceleration
            else
              local tear = entities[i]:ToTear()
              tear.FallingSpeed = 0
            end
          else
            local tear = entities[i]:ToTear()
            entities[i].Velocity = Vector(0, 0)
            tear.FallingAcceleration = -0.1
            tear.FallingSpeed = 0
          end
        elseif entities[i].Type == EntityType.ENTITY_BOMB then
          local bomb = v:ToBomb()
          ---@diagnostic disable-next-line: need-check-nil
          bomb:SetExplosionCountdown(2)
          if v.Variant == 4 then
            bomb.Velocity = Vector(0, 0)
          end
        elseif entities[i].Type == EntityType.ENTITY_LASER then
          if v.Variant ~= 2 then
            local laser = v:ToLaser()
            local data = v:GetData()
            if laser and not data.TimeFrozen and not laser:IsCircleLaser() then
              local newLaser = player:FireBrimstone(Vector.FromAngle(laser.StartAngleDegrees))
              newLaser.Position = laser.Position
              newLaser.DisableFollowParent = true
              local newData = newLaser:GetData()
              newData.TimeFrozen = true
              laser.CollisionDamage = -100
              data.TimeFrozen = true
              laser.DisableFollowParent = true
              laser.Visible = false
            end
            ---@diagnostic disable-next-line: need-check-nil
            laser:SetTimeout(true)
          end
        elseif v.Type == EntityType.ENTITY_KNIFE then
          local data = v:GetData()
          local knife = v:ToKnife()
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
            for i = 1, number do
              local newKnife = player:FireTear(knife.Position, Vector(0, 0), false, true, false)
              local newData = newKnife:GetData()
              newData.Knife = true
              newKnife.TearFlags = 1 << 1
              newKnife.Scale = 1
              newKnife:ResetSpriteScale()
              newKnife.FallingAcceleration = -0.1
              newKnife.FallingSpeed = 0
              newKnife.Height = -10
              stand.randomV.X = 0
              stand.randomV.Y = 1 + offset2
              newKnife.Velocity = stand.randomV:Rotated(knife.Rotation - 90 + offset) * 15 * player.ShotSpeed
              newKnife.CollisionDamage = knife.Charge * (player.Damage) * (3 - brimDamage)
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
    for i, v in pairs(entities) do
      if v:GetData().Knife then
        for o, entity in pairs(entities) do
          if entity:IsVulnerableEnemy() and (not entity:GetData().Knife) and entity.Position:Distance(v.Position) < entity.Size + 7 then
            entity:TakeDamage(v.CollisionDamage, 0, EntityRef(v), 0)
          end
        end
        if player.Position:Distance(v.Position) > 1000 then
          v:Remove()
        end
      end
    end
  end
end

---@param player EntityPlayer
return function(player, standEntity)
  local playerData = player:GetData()
  local standItemData = playerData[stand.Id .. ".Item"]

  if standItemData and player:HasCollectible(standItem) then
    local controler = player.ControllerIndex

    if Input.IsButtonPressed(Settings.KEY_PRIMARY, controler) or Input.IsButtonPressed(Settings.BUTTON_PRIMARY, controler)
    then
      if standItemData.SuperCharge == STATS.SuperMaxCharge then
        DoSuper(player, stand)
      end
    end
  end

  if standItemData then
    UpdateSuper(player, stand)
    UpdateTimeFreeze(player, standItemData)
  end

end
