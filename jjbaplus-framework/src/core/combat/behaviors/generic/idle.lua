local setStat = require("src/core/combat/set_stat")
local targeting = require("src/core/combat/targeting")
local utils = require("src/utils")

local game = Game()
local sfx = SFXManager()

local function resolveCombat(standDef)
    return standDef.combat or {}
end

local function resolveChargeReleaseBehavior(player, standDef, standData, combat, hooks)
    if hooks.getChargeReleaseBehavior then
        return hooks.getChargeReleaseBehavior(player, standDef, standData)
    end
    return combat.chargeReleaseBehavior or "rush"
end

local function resolveIdleFaceAnim(standDef, faceSpriteIndex, roomClear, combat, hooks)
    if hooks.getIdleFaceAnim then
        return hooks.getIdleFaceAnim(standDef, faceSpriteIndex, roomClear)
    end
    if combat.idleAnimMode == "idle_only" then
        return standDef.spIdle[faceSpriteIndex]
    end
    if roomClear then
        return standDef.spIdle[faceSpriteIndex]
    end
    return standDef.spMad[faceSpriteIndex]
end

local function applyPartialChargeRelease(standData, maxcharge, combat, hooks)
    if hooks.onIdleReleasePartialCharge then
        hooks.onIdleReleasePartialCharge(standData, maxcharge)
        return
    end
    if combat.releasePartialCharge == "reset" then
        standData.charge = maxcharge
        return
    end
    standData.charge = math.min(maxcharge, standData.charge + (maxcharge / 90))
end

return function(player, standDef, jsf, shootDir)
    local playerData = player:GetData()
    local input = jsf.input or {}
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local standSprite = standEntity:GetSprite()
    local playerPosition = player.Position
    local sounds = standDef.sounds
    local hooks = standDef.hooks or {}
    local combat = resolveCombat(standDef)

    if standData.behavior ~= "idle" then
        return
    end

    standData.alphagoal = .5

    local cdang = ((playerPosition + Vector(0, -1) - standEntity.Position):GetAngleDegrees() + 180 % 360)
    local tgtang = player:GetHeadDirection() * 90
    if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        tgtang = shootDir:GetAngleDegrees()
    end
    if cdang - 180 > tgtang then cdang = cdang - 360 end
    if tgtang - 180 > cdang then tgtang = tgtang - 360 end
    if input.shoot then standData.posrate = .2 end
    local nextang = utils:Lerp(cdang, tgtang, standData.posrate)
    standData.posrate = .08
    local nextpos = playerPosition + Vector(0, -1) + (Vector.FromAngle(nextang) * 45)

    standEntity.Velocity = nextpos - standEntity.Position

    targeting.updateIdleLockOn(player, standDef, standEntity, standData, input)

    local maxcharge = setStat:MaxCharge(player, standDef)

    local faceSpriteIndex = ((player:GetHeadDirection() + 2) % 4) + 1
    local aimIndex = faceSpriteIndex
    if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        faceSpriteIndex = utils:VecDir(shootDir) + 1
        aimIndex = faceSpriteIndex
    end

    local windSuffix = combat.windAnimSuffix
    if windSuffix == nil then
        windSuffix = hooks.windAnimSuffix or "2"
    end

    local windOnlyAtFull = combat.windOnlyAtFullCharge
    if windOnlyAtFull == nil then
        windOnlyAtFull = hooks.idleWindOnlyAtFullCharge == true
    end

    if not input.shoot then
        standSprite:Play(resolveIdleFaceAnim(standDef, faceSpriteIndex, game:GetRoom():IsClear(), combat, hooks))
        if standData.charge == 0 then
            standData.charge = maxcharge
            standData.behavior = resolveChargeReleaseBehavior(player, standDef, standData, combat, hooks)
            standData.launchdir = input.releasedir
            if standData.launchdir.X == 0 and standData.launchdir.Y == 0 then
                standData.launchdir = Vector(1, 0)
            end
        else
            applyPartialChargeRelease(standData, maxcharge, combat, hooks)
        end
        standData.ready = false
        if game:GetRoom():GetFrameCount() < 1 or not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
            standData.launchto = game:GetRoom():GetClampedPosition(
                playerPosition + ((input.releasedir * standData.range) + (player:GetTearMovementInheritance(input.releasedir) * 10)),
                20
            )
        end
    else
        setStat:Range(player, standDef, standEntity)
        standData.launchto = game:GetRoom():GetClampedPosition(
            playerPosition + ((input.releasedir * standData.range) + (player:GetTearMovementInheritance(shootDir) * 10)),
            20
        )
        local showWind = windOnlyAtFull and standData.charge == maxcharge
            or not windOnlyAtFull and standData.charge > 0
        if showWind then
            standSprite:Play(standDef.spWind[aimIndex])
        elseif standSprite:IsEventTriggered("WindEnd") then
            standSprite:Play(standDef.spWound[aimIndex])
        elseif standData.charge == 0 and not standData.ready then
            standSprite:Play(standDef.spFlash[aimIndex])
            standData.ready = true
            if sounds.punchready then
                sfx:Play(sounds.punchready, .35, 0, false, .98)
            end
        elseif standSprite:IsEventTriggered("FlashEnd") then
            standSprite:Play(standDef.spReady[aimIndex])
        end
        if windSuffix == "2" then
            if standSprite:IsPlaying("Wound2E") or standSprite:IsPlaying("Wound2S") or standSprite:IsPlaying("Wound2W") or standSprite:IsPlaying("Wound2N") then
                standSprite:Play(standDef.spWound[aimIndex])
            end
            if standSprite:IsPlaying("ReadyE") or standSprite:IsPlaying("ReadyS") or standSprite:IsPlaying("ReadyW") or standSprite:IsPlaying("ReadyN") then
                standSprite:Play(standDef.spReady[aimIndex])
            end
        else
            if standSprite:IsPlaying("WoundS") or standSprite:IsPlaying("WoundN") or standSprite:IsPlaying("WoundE") or standSprite:IsPlaying("WoundW") then
                standSprite:Play(standDef.spWound[aimIndex])
            end
            if standSprite:IsPlaying("ReadyS") or standSprite:IsPlaying("ReadyN") or standSprite:IsPlaying("ReadyE") or standSprite:IsPlaying("ReadyW") then
                standSprite:Play(standDef.spReady[aimIndex])
            end
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
