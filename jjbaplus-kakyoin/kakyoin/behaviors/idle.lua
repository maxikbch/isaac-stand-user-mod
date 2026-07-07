local standChecks = require("kakyoin.stand_checks")
local setStat = require("kakyoin.set_stat")
local utils = require("kakyoin.utils")

local game = Game()
local sfx = SFXManager()

return function(player, standDef, jsf, shootDir)
    local playerData = player:GetData()
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local standSprite = standEntity:GetSprite()
    local playerPosition = player.Position
    local sounds = standDef.sounds
    local anims = standDef.animations

    if standData.behavior ~= "idle" then
        return
    end

    standData.alphagoal = 0.5

    local cdang = ((playerPosition + Vector(0, -1) - standEntity.Position):GetAngleDegrees() + 180 % 360)
    local tgtang = player:GetHeadDirection() * 90
    if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        tgtang = shootDir:GetAngleDegrees()
    end
    if cdang - 180 > tgtang then cdang = cdang - 360 end
    if tgtang - 180 > cdang then tgtang = tgtang - 360 end
    if playerData.shoot then standData.posrate = 0.2 end
    local nextang = utils:Lerp(cdang, tgtang, standData.posrate)
    standData.posrate = 0.08
    local nextpos = playerPosition + Vector(0, -1) + (Vector.FromAngle(nextang) * 45)

    standEntity.Velocity = nextpos - standEntity.Position

    local STATS = standDef.stats
    local closedist = (-player.TearHeight * STATS.RangeMult) + 40
    local found = false
    for _, en in ipairs(Isaac.GetRoomEntities()) do
        if standChecks:IsValidEnemy(en, player, standEntity) or standChecks:IsTargetable(en, player, standEntity) then
            local xdif = en.Position.X - player.Position.X
            local ydif = en.Position.Y - player.Position.Y
            if playerData.releasedir.Y ~= 0 then
                if playerData.releasedir.Y * ydif > 0 and math.abs(xdif) < STATS.LockonWidth then
                    if math.abs(ydif) < closedist then
                        found = true
                        standData.tgt = en
                        closedist = math.abs(ydif)
                    end
                end
            else
                if playerData.releasedir.X * xdif > 0 and math.abs(ydif) < STATS.LockonWidth then
                    if math.abs(xdif) < closedist then
                        found = true
                        standData.tgt = en
                        closedist = math.abs(xdif)
                    end
                end
            end
        end
    end
    if found then
        standData.alphagoal = 1
        standData.tgttimer = 10
    elseif standData.tgttimer > 0 and (standChecks:IsValidEnemy(standData.tgt, player, standEntity) or standChecks:IsTargetable(standData.tgt, player, standEntity)) then
        standData.tgttimer = standData.tgttimer - 1
    else
        standData.tgt = nil
    end

    local maxcharge = setStat:MaxCharge(player, standDef)

    local faceSpriteIndex = ((player:GetHeadDirection() + 2) % 4) + 1
    local aimIndex = faceSpriteIndex
    if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        faceSpriteIndex = utils:VecDir(shootDir) + 1
        aimIndex = faceSpriteIndex
    end

    if not playerData.shoot then
        standSprite:Play(anims.spIdle[faceSpriteIndex])
        if standData.charge == 0 then
            standData.charge = maxcharge
            standData.behavior = "splash"
            standData.launchdir = playerData.releasedir
            if standData.launchdir.X == 0 and standData.launchdir.Y == 0 then
                standData.launchdir = Vector(1, 0)
            end
        else
            standData.charge = maxcharge
        end
        standData.ready = false
        if game:GetRoom():GetFrameCount() < 1 or not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
            standData.launchto = game:GetRoom():GetClampedPosition(
                playerPosition + ((playerData.releasedir * standData.range) + (player:GetTearMovementInheritance(playerData.releasedir) * 10)),
                20
            )
        end
    else
        setStat:Range(player, standDef, standEntity)
        standData.launchto = game:GetRoom():GetClampedPosition(
            playerPosition + ((playerData.releasedir * standData.range) + (player:GetTearMovementInheritance(shootDir) * 10)),
            20
        )
        if standData.charge == maxcharge then
            standSprite:Play(anims.spWind[aimIndex])
        elseif standSprite:IsEventTriggered("WindEnd") then
            standSprite:Play(anims.spWound[aimIndex])
        elseif standData.charge == 0 and not standData.ready then
            standSprite:Play(anims.spFlash[aimIndex])
            standData.ready = true
            if sounds.punchready then
                sfx:Play(sounds.punchready, 0.35, 0, false, 0.98)
            end
        elseif standSprite:IsEventTriggered("FlashEnd") then
            standSprite:Play(anims.spReady[aimIndex])
        end
        if standSprite:IsPlaying("WoundS") or standSprite:IsPlaying("WoundN") or standSprite:IsPlaying("WoundE") or standSprite:IsPlaying("WoundW") then
            standSprite:Play(anims.spWound[aimIndex])
        end
        if standSprite:IsPlaying("ReadyS") or standSprite:IsPlaying("ReadyN") or standSprite:IsPlaying("ReadyE") or standSprite:IsPlaying("ReadyW") then
            standSprite:Play(anims.spReady[aimIndex])
        end

        standData.charge = math.max(0, standData.charge - 1)
        if game:GetRoom():GetFrameCount() <= 1 then
            standData.charge = 0
        end
    end

    if playerData.mytgt and playerData.mytgt:Exists() then
        if standData.tgt then
            playerData.mytgt.Position = standData.tgt.Position
        else
            playerData.mytgt.Position = standData.launchto
        end
    end
end
