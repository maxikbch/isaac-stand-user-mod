
local utils = require("src/functions/utils.lua")
local standChecks = require("src/functions/standChecks.lua")

local mod = RegisterMod("Maxo13:StandUser", 1 )
local _log = {}
local game = Game()
local sfx = SFXManager()
local rng = RNG()
local config = Isaac.GetItemConfig()

local SETTINGS = {
	ReapplyCostume = true, -- overrides other costumes which take the same layers as josuke's hair and clothes every room
	VisibleTarget = false, -- shows a target to further assist with aiming
	NoShooting = false, -- josuke cannot shoot! (unless he stands still for 5 seconds)
}

local STATS = {

	ChargeLength = 7,
	RangeMult = 8,
	MinimumRange = 60,
	Punches = 5,
	Damage = .4,
	DamageLastHit = 2.4,
	Knockback = 5,
	KnockbackLastHitMult = 2.5,
	PunchSize = 6,

	KnockbackBirthrightMult = 5,
	KnockbackBossMult = .5,
	LockonWidth = 50,
	ExtraTargetRange = 25,
	ExtraTargetRangeBonus = 20,
	DamageBirthrightFinisher = 1.5,
	DamageBirthrightFinisherB = .8,

}

local CONSTANTS = {

	--ForcedSeed = SeedEffect.SEED_KIDS_MODE,

	NoShootingChargeMult = .4, -- CD charge time multiplier with NoShooting enabled
	PunchesPerExtraShot = 3,
	HomingTargetRangeBonus = 100,
	BFFDamageBonus = 1.5,
	ProptosisRangeMult = .5,
	ChocolateMilkChargeMult = 1,--.5,
	BrimstoneChargeMult = .4,--.16,
	BrimstonePlayerDamageMult = .75,--1.5/3,
	DrFetusChargeMax = 3,
	EpicFetusChargeMult = 1,--.5,
	ParasiteDamageMult = .5,
	CricketsBodyDamageMult = .33,
	BoxOfFriendsPunchesMult = 2,
	SoyMilkPunchesMult = 20,
	LudovicoRangeBonus = 100,
	PiscesKnockbackMult = 2,
	IpecacChargeMult = .5,--.2,
	IpecacDamageMod = .5,
	MagnetForce = 8,
	MonstrosLungChargeMult = .5,--.25,
}

local standUser = {
	Type = Isaac.GetPlayerTypeByName("StandUser"),
	Type2 = Isaac.GetPlayerTypeByName("StandUser", true),
	DamageMult = 6/7,
	Damage = 0,
	Speed = 0.15,
	Range = -3.75,
	Costume1 = Isaac.GetCostumeIdByPath("gfx/characters/costume_josuke.anm2"),
	Costume2 = Isaac.GetCostumeIdByPath("gfx/characters/costume_josuke2.anm2")
}

local taintedStandUser = {
	DamageMult = 6/7,
	Damage = 0.5,
	Speed = 0.15,
	Range = -8.75,
}

local stand = {
	Id = "stand",
	Variant = Isaac.GetEntityVariantByName("Stand"),
	Particle = Isaac.GetEntityVariantByName("Stand Particle"),
	FloatOffset = Vector(0, -36),
	spIdle = {'IdleE', 'IdleS', 'IdleW', 'IdleN'},
	spMad = {'MadE', 'MadS', 'MadW', 'MadN'},
	spWind = {'Wind2E', 'Wind2S', 'Wind2W', 'Wind2N'},
	spWound = {'Wound2E', 'Wound2S', 'Wound2W', 'Wound2N'},
	spFlash = {'FlashE', 'FlashS', 'FlashW', 'FlashN'},
	spReady = {'ReadyE', 'ReadyS', 'ReadyW', 'ReadyN'},
	spRush = {'RushE', 'RushS', 'RushW', 'RushN'},
	spPunch = {'PunchE', 'PunchS', 'PunchW', 'PunchN'},
	spOra = {'OraE', 'OraS', 'OraW', 'OraN'},
	spParticle = {'ParticleE', 'ParticleS', 'ParticleW', 'ParticleN'}
}

local sounds = {
	punchlight = Isaac.GetSoundIdByName("PunchLight"),
	punchheavy = Isaac.GetSoundIdByName("PunchHeavy"),
	punchready = Isaac.GetSoundIdByName("PunchReady"),
	whoosh = Isaac.GetSoundIdByName("Whoosh")
}

local gameunpause = false
local roomframes = 0

function mod:onRender()
	local min = math.max(1, #_log-10)
	for i = min, #_log do
		Isaac.RenderText(i..": ".._log[i], 50, 20+(i-min)*10, 1, 1, 0.9, 1.8)
	end
end

function mod:evaluate_cache(player,flag)
	if player:GetPlayerType() == standUser.Type then
		if flag == 1 then
			player.Damage = (player.Damage * standUser.DamageMult) + standUser.Damage
			if player:HasCollectible(118) then player.Damage = player.Damage * CONSTANTS.BrimstonePlayerDamageMult end
		elseif flag == 8 then
			player.TearHeight = math.min(-7.5, player.TearHeight - standUser.Range)
		elseif flag == 16 then
			player.MoveSpeed = player.MoveSpeed + standUser.Speed
		end
	elseif player:GetPlayerType() == standUser.Type2 then
		if flag == 1 then
			player.Damage = (player.Damage * taintedStandUser.DamageMult) + taintedStandUser.Damage
			if player:HasCollectible(118) then player.Damage = player.Damage * CONSTANTS.BrimstonePlayerDamageMult end
		elseif flag == CacheFlag.CACHE_RANGE then
			player.TearHeight = math.min(-7.5, player.TearHeight - taintedStandUser.Range)
		elseif flag == 16 then
			player.MoveSpeed = player.MoveSpeed + taintedStandUser.Speed
		end
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.evaluate_cache)


function mod:post_update()
	local player = Isaac.GetPlayer(0)
	local playerData = player:GetData()

	--#region AddStandToPlayer
	if (player:GetPlayerType() ~= standUser.Type and player:GetPlayerType() ~= standUser.Type2) then
		if playerData[stand.Id] and playerData[stand.Id]:Exists() then
			playerData[stand.Id]:Remove()
			playerData[stand.Id] = nil
		end
		if playerData.mytgt and playerData.mytgt:Exists() then
			playerData.mytgt:Remove()
			playerData.mytgt = nil
		end
		return
	end
	if not playerData[stand.Id] or not playerData[stand.Id]:Exists() then
		playerData[stand.Id] = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, stand.Variant, 0, player.Position, Vector(0, 0), player)
	end
	--#endregion

	mod:StandUpdate(player)

	--check entities in the room
	for i, en in ipairs(Isaac.GetRoomEntities()) do
		local type = en.Type
		local variant = en.Variant
		--remove old stand entities
		if type == 3 and variant == stand.Variant then
			if not en:GetData().linked then
				en:Remove()
			end
		end
		--particle cleanup
		if type == 1000 and variant == stand.Particle then
			en:GetSprite().Color = Color(1, 1, 1, .3 * (1 / en.FrameCount), 0, 0, 0)
			if en.FrameCount >= 3 then
				en:Remove()
			end
		end
	end

	roomframes = roomframes + 1

end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.post_update)

---@param player EntityPlayer
function mod:SetPunchAmount(player)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	standData.punches = 0
	if player:GetPlayerType() ~= standUser.Type2 then
		standData.maxpunches = STATS.Punches + math.ceil((player.ShotSpeed - 1) * 4 )
	else
		standData.maxpunches = STATS.Punches
	end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then standData.maxpunches = standData.maxpunches + CONSTANTS.PunchesPerExtraShot end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then standData.maxpunches = standData.maxpunches + (CONSTANTS.PunchesPerExtraShot * 3) end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) then standData.maxpunches = standData.maxpunches + (CONSTANTS.PunchesPerExtraShot * 2) end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then standData.maxpunches = standData.maxpunches * CONSTANTS.SoyMilkPunchesMult end
		if player:GetData().usedbox then standData.maxpunches = standData.maxpunches * CONSTANTS.BoxOfFriendsPunchesMult end
end

---@param player EntityPlayer
function mod:SetPunchDamage(player)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	standData.damage = 1
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then standData.damage = standData.damage * CONSTANTS.BFFDamageBonus end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_PARASITE) then standData.damage = standData.damage * CONSTANTS.ParasiteDamageMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY) then standData.damage = standData.damage * CONSTANTS.CricketsBodyDamageMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then standData.damage = standData.damage * CONSTANTS.IpecacDamageMod end
end

---@param player EntityPlayer
---@param shootDir Vector
function mod:StandBehaviors(player, shootDir)
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
		if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then maxcharge = maxcharge * CONSTANTS.ChocolateMilkChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then maxcharge = maxcharge * CONSTANTS.BrimstoneChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then maxcharge = maxcharge * CONSTANTS.EpicFetusChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then maxcharge = maxcharge * CONSTANTS.IpecacChargeMult end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then maxcharge = maxcharge * CONSTANTS.MonstrosLungChargeMult end
		if SETTINGS.NoShooting then maxcharge = maxcharge * CONSTANTS.NoShootingChargeMult end
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
				if player:HasCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS) then standData.range = standData.range * CONSTANTS.ProptosisRangeMult end
				standData.range = math.max(standData.range, STATS.MinimumRange)
				if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then standData.range = standData.range + CONSTANTS.LudovicoRangeBonus end
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
			mod:SetPunchAmount(player)
			mod:SetPunchDamage(player)
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
				if utils:hasbit(player.TearFlags, TearFlags.TEAR_HOMING) then maxdist = maxdist + CONSTANTS.HomingTargetRangeBonus end
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
			if player:GetPlayerType() == standUser.Type2 then
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
					elseif player:GetPlayerType() == standUser.Type2 then
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
				knockback = knockback * CONSTANTS.PiscesKnockbackMult
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
						en.Velocity = en.Velocity + ((hitpos - en.Position):Normalized() * CONSTANTS.MagnetForce)
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

---@param player EntityPlayer
function mod:StandUpdate(player) 
	local playerData = player:GetData()

	--#region StandUpdate
	if playerData[stand.Id] and playerData[stand.Id]:Exists() then
		local standData = playerData[stand.Id]:GetData()
		standData.linked = true
		local standSprite = playerData[stand.Id]:GetSprite()
		local playerPosition = player.Position
		local shootDir = utils:GetShootDir(player)

		--init
		if standData.behavior == nil then
			playerData[stand.Id].PositionOffset = stand.FloatOffset
			playerData.releasedir = Vector(0, 0)
			playerData.standstill = 0
			standData.tgttimer = 0
			standData.charge = player.MaxFireDelay * STATS.ChargeLength
			standData.maxcharge = player.MaxFireDelay * STATS.ChargeLength
			standData.range = 150
			standData.launchdir = Vector(0, 0)
			standData.launchto = playerData[stand.Id].Position
			standData.behavior = 'idle'
			standData.behaviorlast = 'none'
			standData.statetime = 0
			standData.posrate = .08
			standData.alpha = -3
			standData.alphagoal = -3
		end

		if player:GetMovementInput().X == 0 and player:GetMovementInput().Y == 0 then
			playerData.standstill = playerData.standstill + 1
		else
			playerData.standstill = 0
		end

		if SETTINGS.NoShooting and playerData.standstill < 140 then
			player.FireDelay = 10
		end

		--charge input
		playerData.shootpress = false
		playerData.shootrelease = false
		if shootDir:Length() ~= 0 or Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) or player:AreOpposingShootDirectionsPressed() then
			if playerData.shoot == false then
				playerData.shootpress = true
			end
			playerData.shoot = true
			playerData.releasedir = shootDir
		else
			if playerData.shoot == true then
				playerData.shootrelease = true
			end
			playerData.shoot = false
		end

		--temp target
		if SETTINGS.VisibleTarget then
			if not (playerData.mytgt and playerData.mytgt:Exists()) then
				playerData.mytgt = Isaac.Spawn(1000, 30, 0, playerPosition, Vector(0, 0), player)
				playerData.mytgt.RenderZOffset = -10000
				playerData.mytgt:GetSprite().Color = Color(191/255, 218/255, 224/255, .6, 0, 0, 0)
			end
		end

		--float offset
		local floatbounce = 3 * Vector.FromAngle(playerData[stand.Id].FrameCount * 9).Y
		playerData[stand.Id].PositionOffset = stand.FloatOffset + Vector(0, floatbounce)

		--remove punch tear
		if standData.punchtear and standData.punchtear:Exists() then
			standData.punchtear:Remove()
		end

		--states behaviors
		mod:StandBehaviors(player, shootDir)

		--sprite alpha
		if standData.alpha < standData.alphagoal then
			standData.alpha = math.min(standData.alphagoal, standData.alpha + .35)
		elseif standData.alpha > standData.alphagoal then
			standData.alpha = math.max(standData.alphagoal, standData.alpha - .35)
		end
		if standData.alpha <= 0 then
			playerData[stand.Id]:GetSprite().Scale = Vector(0, 0)
		else
			if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
				playerData[stand.Id]:GetSprite().Scale = Vector(1.2, 1.2)
			else
				playerData[stand.Id]:GetSprite().Scale = Vector(1, 1)
			end
		end
		standSprite.Color = Color(1, 1, 1, math.max(0, standData.alpha), 0, 0, 0)

		--state timer
		if standData.behavior ~= standData.behaviorlast then
			standData.behaviorlast = standData.behavior
			standData.statetime = 0
		else
			standData.statetime = standData.statetime + 1
		end
	end
	--#endregion
	
end

--box of friends check
function mod:BoxOfFriends()
	local player = Isaac.GetPlayer(0)
	player:GetData().usedbox = true
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.BoxOfFriends, 357)

function mod:onRoomEnter()
	local player = Isaac.GetPlayer(0)
	if (player:GetPlayerType() ~= standUser.Type and player:GetPlayerType() ~= standUser.Type2) then return end
	local playerData = player:GetData()
	if not playerData[stand.Id] or not playerData[stand.Id]:Exists() then
		playerData[stand.Id] = Isaac.Spawn(3, stand.Variant, 0, player.Position, Vector(0, 0), player)
	end
	local standData = playerData[stand.Id]:GetData()
	local standSprite = playerData[stand.Id]:GetSprite()
	roomframes = 0

	standData.alphagoal = -2.5
	standData.alpha = -2.5
	standData.posrate = 1
	if standData.behavior ~= nil then
		standData.behavior = 'idle'
	end
	standSprite.Color = Color(1, 1, 1, -2.5, 0, 0, 0)
	playerData.usedbox = false

	if SETTINGS.ReapplyCostume and (player:GetPlayerType() == standUser.Type) then
		player:AddNullCostume(standUser.Costume1)
	end
	if SETTINGS.ReapplyCostume and (player:GetPlayerType() == standUser.Type2) then
		player:AddNullCostume(standUser.Costume2)
		local meat = config:GetCollectible(CollectibleType.COLLECTIBLE_MEAT)
		player:AddCostume(meat, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onRoomEnter)

function mod:onPlayerInit() 
	local player = Isaac.GetPlayer(0)

	if (player:GetPlayerType() == standUser.Type or player:GetPlayerType() == standUser.Type2) then
		player:EvaluateItems()
		player:AddNullCostume(standUser.Costume1)
	end
	if (player:GetPlayerType() == standUser.Type or player:GetPlayerType() == standUser.Type2) then
		player:GetData().lastrepair = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod:onPlayerInit())

function mod:input_action(entity, inputhook, buttonaction)
	if entity ~= nil then
		local player = entity:ToPlayer()
		if gameunpause and inputhook == 2 then
			if buttonaction == ButtonAction.ACTION_SHOOTDOWN then
				gameunpause = false
				return 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.input_action)

function mod:post_render()
	mod:onRender()
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.post_render)
