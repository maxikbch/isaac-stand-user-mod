
local STATS = require("src/constants/stats")
local ITEM_MODIFIERS = require("src/constants/item_modifiers")
local SETTINGS = require("src/constants/settings")
local sounds = require("src/constants/sounds")
local character = require("src/constants/character")

local standChecks = require("src/stand/checks")
local setStat = require("src/stand/set_stat")
local StandEffects = require("src/stand/effects")
local utils = require("src/utils")

local sfx = SFXManager()
local rng = RNG()

---@param player EntityPlayer
return function (player, stand, shootDir)

    local playerData = player:GetData()
    ---@type Entity
	local standEntity = playerData[stand.Id]
	local standData = standEntity:GetData()
	local standSprite = playerData[stand.Id]:GetSprite()

    if standData.behavior == 'attack' then
        standData.alphagoal = 1
        --init
        if standData.statetime == 0 then
            if standData.launchdir.Y == -1 then
                standSprite:Play("OraN")
            elseif standData.launchdir.X == 1 then
                standSprite:Play("OraE")
            elseif standData.launchdir.Y == 1 then
                standSprite:Play("OraS")
            elseif standData.launchdir.X == -1 then
                standSprite:Play("OraW")
            end
            setStat:AttackAmount(player, stand)
            setStat:AttackDamage(player, stand)
        end
        --retarget
        if standData.tgt and not standData.tgt.CollisionClass and not standData.tgt:Exists() then
            standData.tgt = nil
        end
        if standData.punches < standData.maxpunches and not (standChecks:IsValidEnemy(standData.tgt, player, standEntity) or standChecks:IsTargetable(standData.tgt, player, standEntity)) and not (standData.tgt and standData.tgt.CollisionClass) then
            standData.tgt = nil
            local maxdist = STATS.ExtraTargetRange + (player.MoveSpeed * STATS.ExtraTargetRangeBonus)
            if utils:hasbit(player.TearFlags, TearFlags.TEAR_HOMING) then maxdist = maxdist + ITEM_MODIFIERS.HomingTargetRangeBonus end
            local dist = maxdist
            for i, en in ipairs(Isaac.GetRoomEntities()) do
                if standChecks:IsValidEnemy(en, player, standEntity) then
                    local dest = utils:AdjPos(-standData.launchdir, en)
                    dist = (playerData[stand.Id].Position - dest):Length()
                    if dist < maxdist then
                        standData.tgt = en
                        maxdist = dist
                    end
                end
            end
            if not standData.tgt and SETTINGS.TargetGridEntities then 
                local gridEntity = standChecks:IsValidGridEntity(standEntity.Position, player, standEntity)
                if gridEntity then 
                    standData.tgt = gridEntity
                end
            end
        end
        if standData.tgt then
            playerData[stand.Id].Velocity = utils:AdjPos(-standData.launchdir, standData.tgt) - playerData[stand.Id].Position
            if not standData.tgt.CollisionClass and standData.tgt.Type == 4 and standData.tgt.Variant ~= 3 and standData.tgt.Variant ~= 4 and  ((standData.tgt.Position - player.Position):Length() > 80 or player:HasCollectible(52)) then
                for gt, av in ipairs(Isaac.GetRoomEntities()) do
                    if av:IsVulnerableEnemy() and av.Type ~= 33 and not av:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                        if (av.Position - standData.tgt.Position):Length() < av.Size + 35 then
                            standData.tgt:ToBomb():SetExplosionCountdown(0)
                            standData.tgt = nil
                            break
                        end
                    end
                end
            end
        else
            playerData[stand.Id].Velocity = playerData[stand.Id].Velocity * .7
        end
        --attack
        if standData.statetime % 4 == 0 and standData.punches < standData.maxpunches then
            standData.punches = standData.punches + 1
            if (not standData.tgt) or (standData.tgt and standChecks:IsTargetable(standData.tgt, player, standEntity) and not standChecks:IsValidEnemy(standData.tgt, player, standEntity) and not standData.tgt.CollisionClass) then
                standData.punches = standData.maxpunches
            end
            if standData.tgt and standData.tgt.CollisionClass then
                ---@diagnostic disable-next-line: param-type-mismatch
                StandEffects:ToGridEntities(player, stand, standData.tgt)
                if not standChecks:IsValidGridEntity(standData.tgt.Position, player, standEntity) and standData.punches < standData.maxpunches then 
                    standData.punches = standData.maxpunches
                end
            end
            if standData.punches == standData.maxpunches then
                if standData.launchdir.Y == -1 then
                    standSprite:Play("PunchN")
                elseif standData.launchdir.X == 1 then
                    standSprite:Play("PunchE")
                elseif standData.launchdir.Y == 1 then
                    standSprite:Play("PunchS")
                elseif standData.launchdir.X == -1 then
                    standSprite:Play("PunchW")
                end
            end
            local hitpos = playerData[stand.Id].Position + (standData.launchdir * 35)
            if not player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) and (not player:HasCollectible(CollectibleType.COLLECTIBLE_EXPLOSIVO) or (rng:RandomInt(100) > 10 + (player.Luck * 2))) then
                local ref = player:FireTear(hitpos, Vector(0, 0), false, false, false, player)
                ref:ToTear():AddTearFlags(TearFlags.TEAR_PIERCING)
                local isfinisher = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and standData.punches + 3 > standData.maxpunches
                if standData.punches == standData.maxpunches or isfinisher then
                    if standData.punches == standData.maxpunches then
                        ref.CollisionDamage = ref.CollisionDamage * (standData.damage * STATS.DamageLastHit)
                    elseif player:GetPlayerType() == character.Type2 then
                        ref.CollisionDamage = ref.CollisionDamage * (standData.damage * STATS.DamageBirthrightFinisherB)
                    else
                        ref.CollisionDamage = ref.CollisionDamage * (standData.damage * STATS.DamageBirthrightFinisher)
                    end
    
                    if standData.tgt then
                        sfx:Play(sounds.punchheavy, .75, 0, false, 1)
                        if player:HasCollectible(317) and standData.punches == standData.maxpunches then
                            local splash = Isaac.Spawn(1000, 53, 0, standData.tgt.Position, Vector(0, 0), player)
                            splash:GetSprite().Scale = Vector(2, 2)
                        end
                    end
                else
                    ref.CollisionDamage = ref.CollisionDamage * (standData.damage * STATS.Damage)
                    if standData.tgt then
                        sfx:Play(sounds.punchlight, .75, 0, false, 1 + math.min(.3,(.015 * standData.punches)))
                    end
                end
                if standData.tgt == nil then
                    sfx:Play(sounds.whoosh, .8, 0, false, 1)
                end
                ref.Scale = STATS.PunchSize
                ref.Height = -20
                ref.FallingSpeed = 0
                ref:GetSprite().Color = Color(0, 0, 0, 0, 0, 0, 0)
                ref:GetSprite().Scale = Vector(0, 0)
                standData.punchtear = ref
            else
                local expdam = player.Damage * standData.damage
                if player:HasCollectible(CollectibleType.COLLECTIBLE_EXPLOSIVO) then expdam = expdam + 30 end
                Isaac.Explode(hitpos, player, expdam)
            end
    
            --knockback
            local knockback = player.ShotSpeed * STATS.Knockback
            if player:HasCollectible(CollectibleType.COLLECTIBLE_PISCES) then
                knockback = knockback * ITEM_MODIFIERS.PiscesKnockbackMult
            end
            local magnet = player:HasCollectible(CollectibleType.COLLECTIBLE_STRANGE_ATTRACTOR)
            for i, en in ipairs(Isaac.GetRoomEntities()) do
                if standChecks:IsValidEnemy(en, player, standEntity) then
                    local bossmult = 1
                    if en:IsBoss() then bossmult = STATS.KnockbackBossMult end
                    local length = (en.Position - hitpos):Length()
                    if length <= 50 then
                        StandEffects:TearEffects(player, stand, en)
                        if standData.punches == standData.maxpunches then
                            if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
                                en.Velocity = en.Velocity + (standData.launchdir * bossmult * knockback * STATS.KnockbackBirthrightMult)
                            else
                                en.Velocity = en.Velocity + (standData.launchdir * bossmult * knockback * STATS.KnockbackLastHitMult)
                            end
                        else
                            en.Velocity = en.Velocity + (standData.launchdir * bossmult * knockback)
                        end
                    end
                    if length <= 150 and length >= 30 and magnet and not en:IsBoss() then
                        en.Velocity = en.Velocity + ((hitpos - en.Position):Normalized() * ITEM_MODIFIERS.MagnetForce)
                    end
                end
            end
        end

        if standData.punches == standData.maxpunches then
            if sfx:IsPlaying(sounds.cryMid) then
                sfx:Stop(sounds.cryMid)
                sfx:Play(sounds.cryFinish, .75, 0, false)
            elseif not sfx:IsPlaying(sounds.cryFinish) and not sfx:IsPlaying(sounds.cry) then
                sfx:Play(sounds.cry, .75, 0, false)
            end
        elseif standData.punches == 0 then
            if not sfx:IsPlaying(sounds.cryStart) then
                sfx:Play(sounds.cryStart, .75, 0, false)
            end
        else 
            if not sfx:IsPlaying(sounds.cryStart) and not sfx:IsPlaying(sounds.cryMid) then
                sfx:Play(sounds.cryMid, .75, 0, true)
            end 
        end

        --return
        if standSprite:IsFinished("PunchN") or standSprite:IsFinished("PunchE") or
        standSprite:IsFinished("PunchS") or standSprite:IsFinished("PunchW") then
            standData.behavior = 'return'
        end
    end
end