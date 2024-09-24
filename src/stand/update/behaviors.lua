

local STATS = require("src/stand/stats")
local SETTINGS = require("src/settings")
local ITEM_MODIFIERS = require("src/item_modifiers")
local sounds = require("src/sounds")
local character = require("src/character")

local standChecks = require("src/stand/checks")
local setStat = require("src/stand/setStat")
local utils = require("src/utils")

local game = Game()
local sfx = SFXManager()
local rng = RNG()

---@param player EntityPlayer
---@param shootDir Vector
local function StandBehaviors(player, stand, roomframes, shootDir)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	local standSprite = playerData[stand.Id]:GetSprite()
	local playerPosition = player.Position

	local isRoomClear = game:GetRoom():IsClear()
	
	if standData.behavior == 'idle' then
		standData.alphagoal = .5
		--position
		local cdang = ((playerPosition + Vector(0, -1) - playerData[stand.Id].Position):GetAngleDegrees() + 180 % 360)
		local tgtang = player:GetHeadDirection() * 90
		if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
			tgtang = shootDir:GetAngleDegrees()
		end
		if cdang - 180 > tgtang then cdang = cdang - 360 end
		if tgtang - 180 > cdang then tgtang = tgtang - 360 end
		if playerData.shoot then standData.posrate = .2 end
		local nextang = utils:Lerp(cdang, tgtang, standData.posrate)
		standData.posrate = .08
		local nextpos = playerPosition + Vector(0, -1) + (Vector.FromAngle(nextang) * 45)

		playerData[stand.Id].Velocity = nextpos - playerData[stand.Id].Position

		--victim target
		local closedist = (-player.TearHeight * STATS.RangeMult) + 40
		local found = false
		local safe = true
		for i, en in ipairs(Isaac.GetRoomEntities()) do
			if standChecks:IsValidEnemy(en) or standChecks:IsTargetable(en) then
				local xdif = en.Position.X - player.Position.X
				local ydif = en.Position.Y - player.Position.Y
				if playerData.releasedir.Y ~= 0 then
					if playerData.releasedir.Y * ydif > 0 and math.abs(xdif) < STATS.LockonWidth then
						if math.abs(ydif) < closedist then
							found = true
							safe = false
							standData.tgt = en
							closedist = math.abs(ydif)
						end
					end
				else
					if playerData.releasedir.X * xdif > 0 and math.abs(ydif) < STATS.LockonWidth then
						if math.abs(xdif) < closedist then
							found = true
							safe = false
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
		elseif standData.tgttimer > 0 and (standChecks:IsValidEnemy(standData.tgt) or standChecks:IsTargetable(standData.tgt)) then
			standData.tgttimer = standData.tgttimer - 1
		else
			standData.tgt = nil
		end

		--charging up
		local maxcharge = player.MaxFireDelay * STATS.ChargeLength
		if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then maxcharge = maxcharge * ITEM_MODIFIERS.ChocolateMilkChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then maxcharge = maxcharge * ITEM_MODIFIERS.BrimstoneChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then maxcharge = maxcharge * ITEM_MODIFIERS.EpicFetusChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then maxcharge = maxcharge * ITEM_MODIFIERS.IpecacChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then maxcharge = maxcharge * ITEM_MODIFIERS.MonstrosLungChargeMult end
		if SETTINGS.NoShooting then maxcharge = maxcharge * ITEM_MODIFIERS.NoShootingChargeMult end
		--if player:HasCollectible(52) then maxcharge = bal.DrFetusChargeMax end
		
		local faceSpriteIndex = ((player:GetHeadDirection() + 2) % 4) + 1
		local aimIndex = ((player:GetHeadDirection() + 2) % 4) + 1
		if player:HasCollectible(329) then
			faceSpriteIndex = utils:VecDir(shootDir) + 1
			aimIndex = utils:VecDir(shootDir) + 1
		end
		if not playerData.shoot then
			if isRoomClear then
				standSprite:Play(stand.spIdle[faceSpriteIndex])
			else
				standSprite:Play(stand.spMad[faceSpriteIndex])
			end
			if standData.charge == 0 then
				standData.charge = maxcharge
				standData.behavior = 'rush'
				standData.launchdir = playerData.releasedir
				if standData.launchdir.X == 0 and standData.launchdir.Y == 0 then standData.launchdir = Vector(1, 0) end
			end
			--repentance update
			--cdd.charge = maxcharge
			standData.charge = math.min(maxcharge, standData.charge + (maxcharge / 90))
			--cdd.charge = utils:Lerp(cdd.charge, maxcharge, 1/60)
			standData.ready = false
			if roomframes < 1 or not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
				standData.launchto = game:GetRoom():GetClampedPosition(playerPosition + ((playerData.releasedir * standData.range) + (player:GetTearMovementInheritance(playerData.releasedir) * 10)), 20)
			end
		else
			standData.range = -player.TearHeight * STATS.RangeMult
				if player:HasCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS) then standData.range = standData.range * ITEM_MODIFIERS.ProptosisRangeMult end
				standData.range = math.max(standData.range, STATS.MinimumRange)
				if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then standData.range = standData.range + ITEM_MODIFIERS.LudovicoRangeBonus end
			standData.launchto = game:GetRoom():GetClampedPosition(playerPosition + ((playerData.releasedir * standData.range) + (player:GetTearMovementInheritance(shootDir) * 10)), 20)
			if standData.charge >0 then
				standSprite:Play(stand.spWind[aimIndex])
			elseif standSprite:IsEventTriggered("WindEnd") then
				standSprite:Play(stand.spWound[aimIndex])
			elseif standData.charge == 0 and not standData.ready then
				standSprite:Play(stand.spFlash[aimIndex])
				standData.ready = true
				sfx:Play(sounds.punchready, .35, 0, false, .98)
			elseif standSprite:IsEventTriggered("FlashEnd") then
				standSprite:Play(stand.spReady[aimIndex])
			end
			if standSprite:IsPlaying("Wound2E") or standSprite:IsPlaying("Wound2S") or standSprite:IsPlaying("Wound2W") or standSprite:IsPlaying("Wound2N") then
				standSprite:Play(stand.spWound[aimIndex])
			end
			if standSprite:IsPlaying("ReadyE") or standSprite:IsPlaying("ReadyS") or standSprite:IsPlaying("ReadyW") or standSprite:IsPlaying("ReadyN") then
				standSprite:Play(stand.spReady[aimIndex])
			end

			standData.charge = math.max(0, standData.charge - 1)
			if roomframes <= 1 then
				standData.charge = 0
			end
		end

		--idle tgt
		if playerData.mytgt and playerData.mytgt:Exists() then
			if standData.tgt then
				playerData.mytgt.Position = standData.tgt.Position
			else
				playerData.mytgt.Position = standData.launchto
			end
		end

	elseif standData.behavior == 'rush' then
		standData.alphagoal = 1
		--init rush
		if standData.statetime == 0 then
			standData.launchpos = playerData[stand.Id].Position
			standData.launchtgt = standData.launchto
			if standData.launchdir.Y == -1 then
				standSprite:Play("RushN")
			elseif standData.launchdir.X == 1 then
				standSprite:Play("RushE")
			elseif standData.launchdir.Y == 1 then
				standSprite:Play("RushS")
			elseif standData.launchdir.X == -1 then
				standSprite:Play("RushW")
			else
				standSprite:Play("RushW")
			end
		end
		--intercept target
		for i, en in ipairs(Isaac.GetRoomEntities()) do
			if standChecks:IsValidEnemy(en) then
				local dest = utils:AdjPos(-standData.launchdir, en)
				local diff = playerData[stand.Id].Position - dest
				if diff:Length() < 45 and diff:Length() < (playerData[stand.Id].Position - standData.launchto):Length() then
					standData.tgt = en
					standData.launchto = dest
				end
			end
		end
		--engage target
		if not (standChecks:IsValidEnemy(standData.tgt) or standChecks:IsTargetable(standData.tgt)) then
			standData.tgt = nil
		end
		if standData.tgt then
			local dest2 = utils:AdjPos(-standData.launchdir, standData.tgt)
			standData.launchto = dest2
		else
			standData.launchto = standData.launchtgt
		end
		--velocity
		local diff2 = standData.launchto - playerData[stand.Id].Position
		playerData[stand.Id].Velocity = diff2:Normalized() * math.min(25, diff2:Length())
		if diff2:Length() < 15 then
			if standData.tgt then
				standData.behavior = 'attack'
			else
				standData.behavior = 'attack'
			end
		end

		local fade = Isaac.Spawn(1000, stand.Particle, 0, playerData[stand.Id].Position, Vector(0, 0), nil)
		local fd = fade:GetData()
		local fs = fade:GetSprite()
		fade.PositionOffset = playerData[stand.Id].PositionOffset
		if standData.launchdir.Y == -1 then
			fs:Play("ParticleN")
		elseif standData.launchdir.X == 1 then
			fs:Play("ParticleE")
		elseif standData.launchdir.Y == 1 then
			fs:Play("ParticleS")
		elseif standData.launchdir.X == -1 then
			fs:Play("ParticleW")
		end
		fs.Color = Color(1, 1, 1, .25, 0, 0, 0)

		if playerData.mytgt and playerData.mytgt:Exists() then
			playerData.mytgt.Position = standData.launchto
		end

	--punch flurry
	elseif standData.behavior == 'attack' then
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
		if standData.tgt and not standData.tgt:Exists() then
			standData.tgt = nil
		end
		if standData.punches < standData.maxpunches and not (standChecks:IsValidEnemy(standData.tgt) or standChecks:IsTargetable(standData.tgt)) then
			standData.tgt = nil
			local maxdist = STATS.ExtraTargetRange + (player.MoveSpeed * STATS.ExtraTargetRangeBonus)
				--if player:HasCollectible(3) or player:HasCollectible(182) or player:HasCollectible(331) or player:GetEffects():HasCollectibleEffect(192) then
				--	maxdist = maxdist + bal.HomingTargetRangeBonus
				--end
				if utils:hasbit(player.TearFlags, TearFlags.TEAR_HOMING) then maxdist = maxdist + ITEM_MODIFIERS.HomingTargetRangeBonus end
			local dist = maxdist
			for i, en in ipairs(Isaac.GetRoomEntities()) do
				if standChecks:IsValidEnemy(en) then
					local dest = utils:AdjPos(-standData.launchdir, en)
					dist = (playerData[stand.Id].Position - dest):Length()
					if dist < maxdist then
						standData.tgt = en
						maxdist = dist
					end
				end
			end
		end
		if standData.tgt then
			playerData[stand.Id].Velocity = utils:AdjPos(-standData.launchdir, standData.tgt) - playerData[stand.Id].Position
			if standData.tgt.Type == 4 and standData.tgt.Variant ~= 3 and standData.tgt.Variant ~= 4 and  ((standData.tgt.Position - player.Position):Length() > 80 or player:HasCollectible(52)) then
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
			local diff = playerData[stand.Id].Position - player.Position
			local cdinrange = false
			--log(player.TearHeight)
			--log(math.floor(diff:Length()))
			standData.punches = standData.punches + 1
			--tainted combo loop
			if player:GetPlayerType() == character.Type2 then
				if cdinrange then
					if standData.punches >= standData.maxpunches then
						standData.punches = 0
					end
				else
					standData.punches = standData.maxpunches
				end
			end
			--skip flurry
			if (not standData.tgt) or (standData.tgt and standChecks:IsTargetable(standData.tgt) and not standChecks:IsValidEnemy(standData.tgt)) then
				standData.punches = standData.maxpunches
			end
			--final punch anim
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
			if not player:HasCollectible(149) and (not player:HasCollectible(401) or (rng:RandomInt(100) > 10 + (player.Luck * 2))) then
				local ref = player:FireTear(hitpos, Vector(0, 0), false, false, false)
				ref:ToTear():AddTearFlags(TearFlags.TEAR_PIERCING)
				local isfinisher = player:HasCollectible(619) and standData.punches + 3 > standData.maxpunches
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
				if player:HasCollectible(401) then expdam = expdam + 30 end
				Isaac.Explode(hitpos, player, expdam)
			end

			--knockback
			local knockback = player.ShotSpeed * STATS.Knockback
			if player:HasCollectible(CollectibleType.COLLECTIBLE_PISCES) then
				knockback = knockback * ITEM_MODIFIERS.PiscesKnockbackMult
			end
			local magnet = player:HasCollectible(CollectibleType.COLLECTIBLE_STRANGE_ATTRACTOR)
			for i, en in ipairs(Isaac.GetRoomEntities()) do
				if standChecks:IsValidEnemy(en) then
					local bossmult = 1
					if en:IsBoss() then bossmult = STATS.KnockbackBossMult end
					local length = (en.Position - hitpos):Length()
					if length <= 50 then
						if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
							en:AddConfusion(EntityRef(player), 40, false)
						else
							en:AddConfusion(EntityRef(player), 10, false)
						end
						if standData.punches == standData.maxpunches then
							if player:HasCollectible(619) then
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
		--return
		if standSprite:IsFinished("PunchN") or standSprite:IsFinished("PunchE") or
		standSprite:IsFinished("PunchS") or standSprite:IsFinished("PunchW") then
			standData.behavior = 'return'
		end

	--return
	elseif standData.behavior == 'return' then
		if standData.alpha <= 0 then
			standData.behavior = 'idle'
			standData.posrate = 1
			standData.Position = player.Position
			standData.Velocity = Vector(0, 0)
			standData.alpha = -3
		else
			standData.alphagoal = -3
			playerData[stand.Id].Velocity = playerData[stand.Id].Velocity * .8
		end
	end
end


return StandBehaviors




