local ControllerOn = false

-- most of this will work at least some of the time

local HGbal = {
	ReapplyCostume = true, -- overrides other costumes which take the same layers as josuke's hair and clothes every room
	VisibleTarget = false, -- shows a target to further assist with aiming
	ForceSeed = true, -- disables achievements, thereby preventing an API bug crash when custom characters kill certain bosses
	KakyoinOnly = true, -- ensures that sp only spawns for josuke, otherwise...
	NoShooting = false, -- josuke cannot shoot! (unless he stands still for 5 seconds)

	ForcedSeed = SeedEffect.SEED_KIDS_MODE,

	ChargeLength = 7,
	RangeMult = 10,
	MinimumRange = 80,
	Punches = 5,
	Damage = .6,
	DamageLastHit = 2.4,
	Knockback = 5,
	KnockbackLastHitMult = 2.5,
	KnockbackBossMult = .5,
	LockonWidth = 50,
	ExtraTargetRange = 10,
	ExtraTargetRangeBonus = 5,
	PunchSize = 6,

	NoShootingChargeMult = .4, -- sp charge time multiplier with NoShooting enabled
	PunchesPerExtraShot = 5,
	HomingTargetRangeBonus = 100,
	BFFDamageBonus = 1.5,
	ProptosisRangeMult = .5,
	ChocolateMilkChargeMult = .5,
	BrimstoneChargeMult = .16,
	BrimstonePlayerDamageMult = 1.5/3,
	DrFetusChargeMax = 3,
	EpicFetusChargeMult = .5,
	ParasiteDamageMult = .5,
	CricketsBodyDamageMult = .33,
	BoxOfFriendsPunchesMult = 2,
	SoyMilkPunchesMult = 20,
	LudovicoRangeBonus = 100,
	PiscesKnockbackMult = 2,
	IpecacChargeMult = .2,
	IpecaspamageMod = .5,
	MagnetForce = 8,
	MonstrosLungChargeMult = .25,

	BossFriendRate = .15,
	AngelFriendRate = .35,
	ItemReviveRate = .35,
	LuckBonus = .03,

	FriendTargetHealth = 20,
	FriendTargetBonus = 3,
	FriendRecoverRate = .75,
	FriendHealthFalloff = .8,
	FriendMaxDamage = 7,
	MaxCharmedSpawns = 3,
	FriendHitPointTax = 10,

	BFFFriendBonus = 2
}

local chalHG = false

TearVariant.Emeralds1 = Isaac.GetEntityVariantByName("Emeralds1")
TearVariant.Emeralds2 = Isaac.GetEntityVariantByName("Emeralds2")
TearVariant.Emeralds3 = Isaac.GetEntityVariantByName("Emeralds3")
TearVariant.Emeralds4 = Isaac.GetEntityVariantByName("Emeralds4")
local EmeraldRadio = Isaac.GetEntityVariantByName("Emerald Radio")
local EmeraldRadioE = false
local i = 15
local hgrPosition = 0
local hgr = nil
local hgrE
local hgrN
local hgrW
local hgrS

StMod = RegisterMod("Stands", 1 )
local _logSP = {}
local game = Game()
local sfx = SFXManager()
local music = MusicManager()
local HGrng = RNG()
local player = Isaac.GetPlayer(0)
local HGconfig = Isaac.GetItemConfig()

local HGstand = {
StandCharge = 0,
StandKey = Keyboard.KEY_LEFT_SHIFT, --Which keyboard key activates wraith mode
StandActive = false,
StandGainPoints = 0.2,
StandCooldown = 0,
StandCooldownPoints = 10,
StandCooldownOn = false,
}



local StMeter = {
  StandMeter = Sprite(),
  charged = ('charged'),
  uncharging = ('uncharging'),
  }

StMeter.StandMeter:Load("gfx/standmeter.anm2", true)

local HGStandIsCharged = false

StandOn = false

local StandMeterXOffset = 60 --Stand Meter HUD sprite offsets
local StandMeterYOffset = 50

local PlayerHasHG = false


HGItem = Isaac.GetItemIdByName("Hierophant Green");
SPItem = Isaac.GetItemIdByName("Star Platinum");

local kakyoin = {
	Type = Isaac.GetPlayerTypeByName("Kakyoin"),
	DamageMult = 6/7,
	Speed = 0.15,
	Range = -8.75,
	Costume1 = Isaac.GetCostumeIdByPath("gfx/characters/costume_kakyoin.anm2"),
	Costume2 = Isaac.GetCostumeIdByPath("gfx/characters/costume_kakyoin2.anm2"),
  
}

local hg = {
	Variant = Isaac.GetEntityVariantByName("Hierophant Green"),
	FloatOffset = Vector(0, -36),
	spIdle = {'IdleE', 'IdleS', 'IdleW', 'IdleN'},
	spWind = {'WindE', 'WindS', 'WindW', 'WindN'},
	spWound = {'WoundE', 'WoundS', 'WoundW', 'WoundN'},
	spSplash = {'SplashE', 'SplashS', 'SplashW', 'SplashN'},
  spFlash = {'FlashE', 'FlashS', 'FlashW', 'FlashN'},
	spReady = {'ReadyE', 'ReadyS', 'ReadyW', 'ReadyN'},
	spRush = {'RushE', 'RushS', 'RushW', 'RushN'},
}

local snd = {
	punchlight = Isaac.GetSoundIdByName("PunchLight"),
	punchheavy = Isaac.GetSoundIdByName("PunchHeavy"),
	punchready = Isaac.GetSoundIdByName("PunchReady"),
	whoosh = Isaac.GetSoundIdByName("Whoosh"),
	rage = Isaac.GetSoundIdByName("Rage"),
  emerald = Isaac.GetSoundIdByName("Emerald"),
  splash = Isaac.GetSoundIdByName("Splash"),
  es = Isaac.GetSoundIdByName("EmeraldSplashu"),
  hg = Isaac.GetSoundIdByName("Hierophant Green"),
  rero = Isaac.GetSoundIdByName("Rero"),
  ikuso = Isaac.GetSoundIdByName("Ikuso"),
}

local particles = {}
local gameunpause = false
local roomframes = 0
local beggars = {}

local SoundButtons = {
  A = Keyboard.KEY_1,
  B = Keyboard.KEY_2,
  C = Keyboard.KEY_3,
  }

--Desactivar Logros 
local NoAchievements = RegisterMod("No Achievements", 1)
function NoAchievements:onInit()
	local player = Isaac.GetPlayer(0)
	if HGbal.ForceSeed and (player:GetPlayerType() == kakyoin.Type or not HGbal.KakyoinOnly) then
    Game():GetSeeds():AddSeedEffect(HGbal.ForcedSeed)
	end
end
NoAchievements:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, NoAchievements.onInit)
--NO TOCAR
local function log(...)
	local args = {...}
	for _, v in ipairs(args) do
		table.insert(_logSP, tostring(v))
	end
end



function StMod:onRender()
	local min = math.max(1, #_logSP-10)
	for i = min, #_logSP do
		Isaac.RenderText(i..": ".._logSP[i], 50, 20+(i-min)*10, 1, 1, 0.9, 1.8)
	end
end

local function Lerp(first,second,percent)
	return (first + (second - first)*percent)
end

local function bit(x,p)
	return x * 2 ^ p
end
local function hasbit(x, p)
	return x % (p + p) >= p
end
local function setbit(x, p)
	return hasbit(x, p) and x or x + p
end
local function clearbit(x, p)
	return hasbit(x, p) and x - p or x
end

local function Vehgir(vec)
	return(math.floor(((vec:GetAngleDegrees() % 360) / 90) + .5) % 4)
end

local function IsTargetable(en)
	local player = Isaac.GetPlayer(0)
	if en and en:Exists() then
		if (en.Type == 5 and en.Variant == 100 and en.SubType == 337) or -- broken watch to stopwatch
		(en.Type == 5 and en.Variant == 100 and (en.SubType == 238 or en.SubType == 239)) or -- key piece to familiar
		(en.Type == 5 and en.Variant == 100 and en.SubType == 298) or -- unicorn stump to my little unicorn
		(en.Type == 5 and en.Variant == 100 and en.SubType == 336) or -- dead onion to sad onion
		(en.Type == 5 and en.Variant == 100 and en.SubType == 341) or -- torn photo to polaroid
		(en.Type == 5 and en.Variant == 350 and en.SubType == 101) or -- dim bulb to vibrant bulb
		(en.Type == 6 and en:GetSprite():IsPlaying("Broken") and player:GetData().lastrepair < game:GetLevel():GetStage()) or -- machine fix
		(en.Type == 69 and en.Variant == 1) or -- lokii to loki
		--(en.Type == 291) or -- remove pitfall
		(en.Type == 4) then -- punch bomb
			return true
		end
	end
	return false
end

local function CanPush(en)
	return en and
		--(en.Type == 302 or -- stoney
		en.Type == 4 and not en:GetSprite():IsPlaying("Explode") -- bomb
		--en.Type == 27 or -- host
		--en.Type == 204) -- mobile host
end

local function IsValidEnemy(en)
	return en and ((en:IsVulnerableEnemy() and en.HitPoints > 0) or CanPush(en)) and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end






local function AdjPos(dir, en)
	return en.Position + Vector(0, 0) + (dir * (en.Size + 45))
end


  StMod:AddCallback( ModCallbacks.MC_NPC_UPDATE, StMod.NPCUpdate, player);
--Stand
function StMod:post_update()
	local player = Isaac.GetPlayer(0)
	local d = player:GetData()
  if not player:HasCollectible(HGItem) then PlayerHasHG = false end
  if player:HasCollectible(HGItem) then PlayerHasHG = true end
  if player:GetPlayerType() == kakyoin.Type then player:AddCollectible(HGItem, 0 , false) end
  if PlayerHasHG == true then
	if not d.hg or not d.hg:Exists() then
		d.hg = Isaac.Spawn(3, hg.Variant, 0, player.Position, Vector(0, 0), player)
	end
	if d.hg and d.hg:Exists() then
		local hgd = d.hg:GetData()
		  hgd.linked = true
		local hgs = d.hg:GetSprite()
		local ppos = player.Position
		local pvel = player.Velocity
		local shootdir = player:GetShootingInput()

		if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) then
			if shootdir.X == 0 and shootdir.Y == 0 then
				shootdir = Vector(-1, 0):Rotated(player:GetHeadDirection() * 90)
			end
		end

		local xx = shootdir.X
		local yy = shootdir.Y
		if yy > .5 then
			yy = 1
			xx = 0
		elseif yy < -.5 then
			yy = -1
			xx = 0
		else
			yy = 0
			if xx > .5 then
				xx = 1
			elseif xx < -.5 then
				xx = -1
			else
				xx = 0
			end
		end
		shootdir = Vector(xx, yy)

		local movedir = player:GetMovementInput()
		local isclear = game:GetRoom():IsClear()

		--init
		if hgd.behavior == nil then
			d.hg.PositionOffset = hg.FloatOffset
			d.releasedir = Vector(0, 0)
			d.standstill = 0
			hgd.tgttimer = 0
			hgd.charge = player.MaxFireDelay * HGbal.ChargeLength
			hgd.maxcharge = player.MaxFireDelay * HGbal.ChargeLength
			hgd.range = 150
			hgd.launchdir = Vector(0, 0)
			hgd.launchto = d.hg.Position
			hgd.behavior = 'idle'
			hgd.behaviorlast = 'none'
			hgd.statetime = 0
			hgd.posrate = .08
			hgd.alpha = -3
			hgd.alphagoal = -3
		end

		if player:GetMovementInput().X == 0 and player:GetMovementInput().Y == 0 then
			d.standstill = d.standstill + 1
		else
			d.standstill = 0
		end

		if HGbal.NoShooting and d.standstill < 140 then
			player.FireDelay = 10
		end

		--charge input
		d.shootpress = false
		d.shootrelease = false
		if shootdir:Length() ~= 0 or Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) or player:AreOpposingShootDirectionsPressed() then
			if d.shoot == false then
				d.shootpress = true
			end
			d.shoot = true
			d.releasedir = shootdir
		else
			if d.shoot == true then
				d.shootrelease = true
			end
			d.shoot = false
		end

		--temp target
		if HGbal.VisibleTarget then
			if not (d.mytgt and d.mytgt:Exists()) then
				d.mytgt = Isaac.Spawn(1000, 30, 0, ppos, Vector(0, 0), player)
				d.mytgt.RenderZOffset = -10000
				d.mytgt:GetSprite().Color = Color(191/255, 218/255, 224/255, .6, 0, 0, 0)
			end
		end

		--float offset
		local floatbounce = 3 * Vector.FromAngle(d.hg.FrameCount * 9).Y
		d.hg.PositionOffset = hg.FloatOffset + Vector(0, floatbounce)

		--remove punch tear
		if hgd.punchtear and hgd.punchtear:Exists() then
			hgd.punchtear:Remove()
		end
    
   
		--idle
		if hgd.behavior == 'idle' then
			hgd.alphagoal = .5
			--position
			local hgang = ((ppos + Vector(0, -1) - d.hg.Position):GetAngleDegrees() + 180 % 360)
			local tgtang = player:GetHeadDirection() * 90
			if player:HasCollectible(329) then
				tgtang = shootdir:GetAngleDegrees()
			end
			if hgang - 180 > tgtang then hgang = hgang - 360 end
			if tgtang - 180 > hgang then tgtang = tgtang - 360 end
			if d.shoot then hgd.posrate = .2 end
			local nextang = Lerp(hgang, tgtang, hgd.posrate)
			hgd.posrate = .08
			local nextpos = ppos + Vector(0, -1) + (Vector.FromAngle(nextang) * 45)

			d.hg.Velocity = nextpos - d.hg.Position

			--victim target
			local closedist = (-player.TearHeight * HGbal.RangeMult) + 40
			local found = false
			local safe = true
			for i, en in ipairs(Isaac.GetRoomEntities()) do
				if IsValidEnemy(en) or IsTargetable(en) then
					local xdif = en.Position.X - player.Position.X
					local ydif = en.Position.Y - player.Position.Y
					if d.releasedir.Y ~= 0 then
						if d.releasedir.Y * ydif > 0 and math.abs(xdif) < HGbal.LockonWidth then
							if math.abs(ydif) < closedist then
								found = true
								safe = false
								hgd.tgt = en
								closedist = math.abs(ydif)
							end
						end
					else
						if d.releasedir.X * xdif > 0 and math.abs(ydif) < HGbal.LockonWidth then
							if math.abs(xdif) < closedist then
								found = true
								safe = false
								hgd.tgt = en
								closedist = math.abs(xdif)
							end
						end
					end
				end
			end
			if found then
				hgd.alphagoal = 1
				hgd.tgttimer = 10
			elseif hgd.tgttimer > 0 and (IsValidEnemy(hgd.tgt) or IsTargetable(hgd.tgt)) then
				hgd.tgttimer = hgd.tgttimer - 1
			else
				hgd.tgt = nil
			end

			--charging up
			hgd.maxcharge = player.MaxFireDelay * HGbal.ChargeLength
				if player:HasCollectible(69) then hgd.maxcharge = hgd.maxcharge * HGbal.ChocolateMilkChargeMult end
				if player:HasCollectible(118) then hgd.maxcharge = hgd.maxcharge * HGbal.BrimstoneChargeMult end
				if player:HasCollectible(168) then hgd.maxcharge = hgd.maxcharge * HGbal.EpicFetusChargeMult end
				if player:HasCollectible(149) then hgd.maxcharge = hgd.maxcharge * HGbal.IpecacChargeMult end
				if player:HasCollectible(229) then hgd.maxcharge = hgd.maxcharge * HGbal.MonstrosLungChargeMult end
				if HGbal.NoShooting then hgd.maxcharge = hgd.maxcharge * HGbal.NoShootingChargeMult end
				if player:HasCollectible(52) then hgd.maxcharge = HGbal.DrFetusChargeMax end
			local spfaceind = ((player:GetHeadDirection() + 2) % 4) + 1
			local spaimind = ((player:GetHeadDirection() + 2) % 4) + 1
			if player:HasCollectible(329) then
				spfaceind = Vehgir(shootdir) + 1
				spaimind = Vehgir(shootdir) + 1
			end
			if not d.shoot then
					hgs:Play(hg.spIdle[spfaceind])
         --20 meters emerald splash
      local controler = player.ControllerIndex
      if HGStandIsCharged == true then
      if Input.IsButtonPressed(HGstand.StandKey, controler) == true or (ControllerOn == true and Input.IsActionTriggered(ButtonAction.ACTION_DROP, controler)) then
           hgd.behavior = 'rush'
           hgd.launchdir = d.releasedir
					if hgd.launchdir.X == 0 and hgd.launchdir.Y == 0 then hgd.launchdir = Vector(1, 0) end
      end
    end
      if hgd.charge == 0 then
					hgd.behavior = 'splash'
					hgd.launchdir = d.releasedir
					if hgd.launchdir.X == 0 and hgd.launchdir.Y == 0 then hgd.launchdir = Vector(1, 0) end
				end
				hgd.charge = hgd.maxcharge
				hgd.ready = false
				if roomframes < 1 or not player:HasCollectible(329) then
					hgd.launchto = game:GetRoom():GetClampedPosition(ppos + ((d.releasedir * hgd.range) + (player:GetTearMovementInheritance(d.releasedir) * 10)), 20)
				end
			else
				hgd.range = -player.TearHeight * HGbal.RangeMult
					if player:HasCollectible(261) then hgd.range = hgd.range * HGbal.ProptosisRangeMult end
					hgd.range = math.max(hgd.range, HGbal.MinimumRange)
					if player:HasCollectible(329) then hgd.range = hgd.range + HGbal.LudovicoRangeBonus end
				hgd.launchto = game:GetRoom():GetClampedPosition(ppos + ((d.releasedir * hgd.range) + (player:GetTearMovementInheritance(shootdir) * 10)), 20)
				if hgd.charge == hgd.maxcharge then
					hgs:Play(hg.spWind[spaimind])
				elseif hgs:IsEventTriggered("WindEnd") then
					hgs:Play(hg.spWound[spaimind])
				elseif hgd.charge == 0 and not hgd.ready then
					hgs:Play(hg.spFlash[spaimind])
					hgd.ready = true
				elseif hgs:IsEventTriggered("FlashEnd") then
					hgs:Play(hg.spReady[spaimind])
				end
				if hgs:IsPlaying("Wound2E") or hgs:IsPlaying("Wound2S") or hgs:IsPlaying("Wound2W") or hgs:IsPlaying("Wound2N") then
					hgs:Play(hg.spWound[spaimind])
				end
				if hgs:IsPlaying("ReadyE") or hgs:IsPlaying("ReadyS") or hgs:IsPlaying("ReadyW") or hgs:IsPlaying("ReadyN") then
					hgs:Play(hg.spReady[spaimind])
				end

				hgd.charge = math.max(0, hgd.charge - 1)
			end

			--idle tgt
			if d.mytgt and d.mytgt:Exists() then
				if hgd.tgt then
					d.mytgt.Position = hgd.tgt.Position
				else
					d.mytgt.Position = hgd.launchto
				end
			end



		--punch flurry
  elseif hgd.behavior == 'splash' then
      sfx:Play(snd.es,2,0,false,1)
			hgd.alphagoal = 1
			--init
      
			if hgd.statetime == 0 then
        if hgd.launchdir.Y == -1 then
					hgs:Play("SplashN")
				elseif hgd.launchdir.X == 1 then
					hgs:Play("SplashE")
				elseif hgd.launchdir.Y == 1 then
					hgs:Play("SplashS")
				elseif hgd.launchdir.X == -1 then
					hgs:Play("SplashW")
				end
        	hgd.punches = 0
				hgd.maxpunches = HGbal.Punches
					if player:HasCollectible(245) then hgd.maxpunches = hgd.maxpunches + HGbal.PunchesPerExtraShot end
					if player:HasCollectible(153) then hgd.maxpunches = hgd.maxpunches + (HGbal.PunchesPerExtraShot * 3) end
					if player:HasCollectible(2) then hgd.maxpunches = hgd.maxpunches + (HGbal.PunchesPerExtraShot * 2) end
					if player:GetData().usedbox then hgd.maxpunches = hgd.maxpunches * HGbal.BoxOfFriendsPunchesMult end
					if player:HasCollectible(330) then hgd.maxpunches = hgd.maxpunches * HGbal.SoyMilkPunchesMult end
					if player:GetData().rage then hgd.maxpunches = hgd.maxpunches * HGbal.RagePunchMult end
				hgd.damage = 1
					if player:HasCollectible(247) then hgd.damage = hgd.damage * HGbal.BFFDamageBonus end
					if player:HasCollectible(104) then hgd.damage = hgd.damage * HGbal.ParasiteDamageMult end
					if player:HasCollectible(224) then hgd.damage = hgd.damage * HGbal.CricketsBodyDamageMult end
					if player:HasCollectible(149) then hgd.damage = hgd.damage * HGbal.IpecahgamageMod end
          end
         --attack
        if hgd.punches < hgd.maxpunches then
          local splashS = d.hg.Position + Vector(0,20)
          local splashN = d.hg.Position - Vector(0,20)
          local splashE = d.hg.Position - Vector(20,0)
          local splashO = d.hg.Position + Vector(20,0)
				if hgd.launchdir.Y == -1 then
          Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds1, 0, splashN, Vector.FromAngle(270):__mul(25), nil);
				elseif hgd.launchdir.X == 1 then
          Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds2, 0, splashO, Vector.FromAngle(0):__mul(25), nil);
				elseif hgd.launchdir.Y == 1 then
          Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds1, 0, splashS, Vector.FromAngle(90):__mul(25), nil);
				elseif hgd.launchdir.X == -1 then
          Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds2, 0, splashE, Vector.FromAngle(180):__mul(25), nil);
				end
        hgd.punches = hgd.punches + 1
       elseif hgd.punches == hgd.maxpunches then
         hgd.behavior = 'return'
        end
    --rush state
		elseif hgd.behavior == 'rush' then
			hgd.alphagoal = 1
       --init rush
			if hgd.statetime == 0 then
				hgd.launchpos = d.hg.Position
				hgd.launchtgt = hgd.launchto
        sfx:Play(snd.emerald,2,0,false,1)
				if hgd.launchdir.Y == -1 then
					hgs:Play("IdleN")
				elseif hgd.launchdir.X == 1 then
					hgs:Play("IdleE")
				elseif hgd.launchdir.Y == 1 then
					hgs:Play("IdleS")
				elseif hgd.launchdir.X == -1 then
					hgs:Play("IdleW")
				else
					hgs:Play("IdleW")
				end
			end
			--intercept target
			for i, en in ipairs(Isaac.GetRoomEntities()) do
				if IsValidEnemy(en) then
					local dest = AdjPos(-hgd.launchdir, en)
					local diff = d.hg.Position - dest
					if diff:Length() < 45 and diff:Length() < (d.hg.Position - hgd.launchto):Length() then
						hgd.tgt = en
						hgd.launchto = dest
					end
				end
			end
			--engage target
			if not (IsValidEnemy(hgd.tgt) or IsTargetable(hgd.tgt)) then
				hgd.tgt = nil
			end
			if hgd.tgt then
				local dest2 = AdjPos(-hgd.launchdir, hgd.tgt)
				hgd.launchto = dest2
			else
				hgd.launchto = hgd.launchtgt
			end
			--velocity
			local diff2 = hgd.launchto - d.hg.Position
			d.hg.Velocity = diff2:Normalized() * math.min(25, diff2:Length())
			if diff2:Length() < 15 then
				if hgd.tgt then
					hgd.behavior = 'radio'
				else
					hgd.behavior = 'idle'
				end
			end
    --radio state
  elseif hgd.behavior == "radio" then
    if EmeraldRadioE == false then
    hgr = Isaac.Spawn(0, EmeraldRadio, 0, d.hg.Position, Vector(0, 0), nil);
    EmeraldRadioE = true
    hgrPosition = d.hg.Position
    hgrS = hgrPosition - Vector(0, 200)
    hgrE = hgrPosition + Vector(200, 0)
    hgrN = hgrPosition + Vector(0, 200)
    hgrW = hgrPosition - Vector(200, 0)
    sfx:Play(snd.splash,2,0,false,1)
  end
    hgd.alpha = -100
     if i > 0 then
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds3, 0, hgrS, Vector.FromAngle(75):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds1, 0, hgrS, Vector.FromAngle(90):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds4, 0, hgrS, Vector.FromAngle(105):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds3, 0, hgrW, Vector.FromAngle(345):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds1, 0, hgrW, Vector.FromAngle(0):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds4, 0, hgrW, Vector.FromAngle(15):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds3, 0, hgrN, Vector.FromAngle(255):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds1, 0, hgrN, Vector.FromAngle(270):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds4, 0, hgrN, Vector.FromAngle(285):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds3, 0, hgrE, Vector.FromAngle(165):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds1, 0, hgrE, Vector.FromAngle(180):__mul(25), nil);
      Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.Emeralds4, 0, hgrE, Vector.FromAngle(195):__mul(25), nil);
      i = i - 1
    else
      hgd.behavior = 'return'
      EmeraldRadioE = false
      HGstand.StandCharge = 0
      HGStandIsCharged = false
      HGstand.StandCharge = 0
      HGstand.StandActive = true
      HGstand.StandCooldown = HGstand.StandCooldownPoints
      i = 15
      hgr:Remove ()
    end
    --return
		elseif hgd.behavior == 'return' then
			if hgd.alpha <= 0 then
				hgd.behavior = 'idle'
				hgd.posrate = 1
				hgd.Position = player.Position
				hgd.Velocity = Vector(0, 0)
				hgd.alpha = -3
			else
				hgd.alphagoal = -3
				d.hg.Velocity = d.hg.Velocity * .8
			end
		end

		--sprite alpha
		if hgd.alpha < hgd.alphagoal then
			hgd.alpha = math.min(hgd.alphagoal, hgd.alpha + .35)
		elseif hgd.alpha > hgd.alphagoal then
			hgd.alpha = math.max(hgd.alphagoal, hgd.alpha - .35)
		end
		if hgd.alpha <= 0 then
			d.hg:GetSprite().Scale = Vector(0, 0)
		else
			if player:HasCollectible(247) then
				d.hg:GetSprite().Scale = Vector(1.2, 1.2)
			else
				d.hg:GetSprite().Scale = Vector(1, 1)
			end
		end
		hgs.Color = Color(1, 1, 1, math.max(0, hgd.alpha), 0, 0, 0)

		--state timer
		if hgd.behavior ~= hgd.behaviorlast then
			hgd.behaviorlast = hgd.behavior
			hgd.statetime = 0
		else
			hgd.statetime = hgd.statetime + 1
		end
	end

	--entitehe
	local charmcount = 0
	local oldest = 0
	for i, en in ipairs(Isaac.GetRoomEntities()) do
		local type = en.Type
		local variant = en.Variant
		local subtype = en.SubType
      
      --no old sp
		if type == 3 and variant == hg.Variant then
			if not en:GetData().linked then
				en:Remove()
			end
		end
    
		--limit max friends
		if d.friend and en:IsEnemy() and en:HasEntityFlags(EntityFlag.FLAG_CHARM) then -- check parent?
			charmcount = charmcount + 1
			if oldest == 0 or oldest.FrameCount < en.FrameCount then
				oldest = en
			end

	if oldest ~= 0 and charmcount > HGbal.MaxCharmedSpawns then
		oldest:Kill()
	end


	--friend management
	if d.friend and roomframes > 1 then
		if d.friend:Exists() ~= true or d.friend.HitPoints <= 0 or d.friend:IsDead() then
			d.friend = nil
		end
	end

	if roomframes == 1 and d.friend and d.friend.HitPoints > 0 then
		-- friend management
		if d.friend and not d.friend:Exists() then
			spawn = Isaac.Spawn(d.friend.Type, d.friend.Variant, d.friend.SubType, Isaac.GetFreeNearPosition(player.Position, 40), Vector(0, 0), player)
			spawn.HitPoints = d.friend.HitPoints
			spawn:AddCharmed(100000)
			spawn:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)

			if not game:GetRoom():IsClear() then
				d.tgthp = d.tgthp * HGbal.FriendHealthFalloff
				spawn.HitPoints = Lerp(d.friend.HitPoints - HGbal.FriendHitPointTax, d.tgthp, HGbal.FriendRecoverRate)
			end

			d.friend = spawn
		end
	end
	roomframes = roomframes + 1


end
end
else
if d.hg and d.hg:Exists() then
			d.hg:Remove()
			d.hg = nil
		end
		if d.mytgt and d.mytgt:Exists() then
			d.mytgt:Remove()
			d.mytgt = nil
		end
  end
  local controler = player.ControllerIndex
  ---Sound 1
if Input.IsButtonPressed(SoundButtons.A, controler) == true and player:GetPlayerType() == kakyoin.Type then
  sfx:Play(snd.hg,2,0,false,1)
end
---Sound 2
if Input.IsButtonPressed(SoundButtons.B, controler) == true and player:GetPlayerType() == kakyoin.Type then
  sfx:Play(snd.ikuso,2,0,false,1)
end
---Sound 3
if Input.IsButtonPressed(SoundButtons.C, controler) == true and player:GetPlayerType() == kakyoin.Type then
  sfx:Play(snd.rero,2,0,false,1)
end
  end
StMod:AddCallback(ModCallbacks.MC_POST_UPDATE, StMod.post_update)

function StMod:onRoomEnter()
	local player = Isaac.GetPlayer(0)
	if HGbal.ReapplyCostume and player:GetPlayerType() == kakyoin.Type then
		player:AddNullCostume(kakyoin.Costume1)
	end
  end
StMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, StMod.onRoomEnter)
--box of friends check
function StMod:BoxOfFriends()
	local player = Isaac.GetPlayer(0)
	player:GetData().usedbox = true
	return true
end
StMod:AddCallback(ModCallbacks.MC_USE_ITEM, StMod.BoxOfFriends, 357)

local function getScreenCenterPosition()
  local room = game:GetRoom()
  local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
  local pos = room:GetCenterPos()
  if centerOffset.X > 260 then
    pos.X = pos.X - 260
  end
  if centerOffset.Y > 140 then
      pos.Y = pos.Y - 140
  end
  return Isaac.WorldToRenderPosition(pos, false)
end

function StMod:onRender() 
 if PlayerHasHG  == true then
  local room = Game():GetRoom()
    --Stand meter
    StMeter.StandMeter:SetOverlayRenderPriority(true)
     if HGStandIsCharged == false then
        StMeter.StandMeter:SetFrame("charging", math.floor(HGstand.StandCharge))
      elseif HGStandIsCharged == true then
         StMeter.StandMeter:Play("charged")
      end
      StMeter.StandMeter:Render(Vector(StandMeterXOffset,StandMeterYOffset), Vector(0,0), Vector(0,0))
    end
    end
StMod:AddCallback(ModCallbacks.MC_POST_RENDER, StMod.onRender)

function StMod:StandAdd()
   if PlayerHasHG  == true then
  if HGstand.StandActive == false then
if HGstand.StandCharge < 20 then
  HGstand.StandCharge = HGstand.StandCharge + HGstand.StandGainPoints
  end
if HGstand.StandCharge > 20 then
  HGstand.StandCharge = 20
end
end
end
end
StMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, StMod.StandAdd)

local function OnUpdate(a)
  local player = Isaac.GetPlayer(0)
   if HGstand.StandCharge == 20 then
        HGStandIsCharged = true
      else
        HGStandIsCharged = false
      end
if Game():GetFrameCount() == 1 then --On new run, reset StandCharge
			HGstand.StandCharge = 0
      Isaac.SaveModData(StMod, tostring(0))
    end
if HGstand.StandActive == true then
  if HGstand.StandCooldownOn == false then
   HGstand.StandCooldownOn = true
end
end
if HGstand.StandCooldownOn == true then
   if HGstand.StandCooldown == 0 then
      HGstand.StandCooldownOn = false
      HGstand.StandActive = false
end
if HGstand.StandCooldown > 0 then
  HGstand.StandCooldown = HGstand.StandCooldown - 1
end
end
end
StMod:AddCallback(ModCallbacks.MC_POST_UPDATE, OnUpdate)