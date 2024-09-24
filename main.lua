
local utils = require("src/utils")
local StandBehaviors = require("src/stand/behaviors")

local mod = RegisterMod("Maxo13:StandUser", 1 )
local _log = {}
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

local ITEM_MODIFIERS = {

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

local character = {
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

local gameunpause = false
local roomframes = 0

function mod:onRender()
	local min = math.max(1, #_log-10)
	for i = min, #_log do
		Isaac.RenderText(i..": ".._log[i], 50, 20+(i-min)*10, 1, 1, 0.9, 1.8)
	end
end

function mod:evaluate_cache(player,flag)
	if player:GetPlayerType() == character.Type then
		if flag == 1 then
			player.Damage = (player.Damage * character.DamageMult) + character.Damage
			if player:HasCollectible(118) then player.Damage = player.Damage * ITEM_MODIFIERS.BrimstonePlayerDamageMult end
		elseif flag == 8 then
			player.TearHeight = math.min(-7.5, player.TearHeight - character.Range)
		elseif flag == 16 then
			player.MoveSpeed = player.MoveSpeed + character.Speed
		end
	elseif player:GetPlayerType() == character.Type2 then
		if flag == 1 then
			player.Damage = (player.Damage * taintedStandUser.DamageMult) + taintedStandUser.Damage
			if player:HasCollectible(118) then player.Damage = player.Damage * ITEM_MODIFIERS.BrimstonePlayerDamageMult end
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
	if (player:GetPlayerType() ~= character.Type and player:GetPlayerType() ~= character.Type2) then
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
		StandBehaviors(player, stand, roomframes, shootDir)

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
	if (player:GetPlayerType() ~= character.Type and player:GetPlayerType() ~= character.Type2) then return end
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

	if SETTINGS.ReapplyCostume and (player:GetPlayerType() == character.Type) then
		player:AddNullCostume(character.Costume1)
	end
	if SETTINGS.ReapplyCostume and (player:GetPlayerType() == character.Type2) then
		player:AddNullCostume(character.Costume2)
		local meat = config:GetCollectible(CollectibleType.COLLECTIBLE_MEAT)
		player:AddCostume(meat, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onRoomEnter)

function mod:onPlayerInit() 
	local player = Isaac.GetPlayer(0)

	if (player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2) then
		player:EvaluateItems()
		player:AddNullCostume(character.Costume1)
	end
	if (player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2) then
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
