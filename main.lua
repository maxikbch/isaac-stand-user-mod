
local SETTINGS = require("src/constants/settings")
local ITEM_MODIFIERS = require("src/constants/item_modifiers")
local STATS = require("src/constants/stats")
local character = require("src/constants/character")
local taintedCharacter = require("src/constants/tainted_character")
local stand = require("src/constants/stand")

local utils = require("src/utils")

local StandUpdate = require("src/stand/update")
local SetStand = require("src/stand/set")
local StandClear = require("src/stand/clear")
local StandUltimate = require("src/stand/ultimate")

local mod = RegisterMod("Maxo13:StandUser", 1 )
local config = Isaac.GetItemConfig()
local sfx = SFXManager()

local StandMeter = 
{
	StandMeter = Sprite(),
	charging = 'charging',
	charged = 'charged',
	uncharging = 'uncharging',

	--Stand Meter HUD sprite offsets
	XOffset = 60, 
	YOffset = 50
}
  
StandMeter.StandMeter:Load("gfx/stand_user/stand_meter.anm2", true)
StandMeter.StandMeter.PlaybackSpeed = 0.1

local roomframes = 0

function mod:onRender()
	local player = Isaac.GetPlayer(0)
	local playerData = player:GetData()

	if SETTINGS.HasUltimate then

		local standData = playerData[stand.Id]:GetData()
		local charge = standData.UltimateCharge or 0
		local duration = standData.UltimateDuration or 0

		if duration > 0 then 
			StandMeter.StandMeter:SetFrame(StandMeter.uncharging, 22 - math.floor(duration / STATS.UltimateDuration * 22))
		elseif charge == STATS.UltimateMaxCharge then
			if not StandMeter.StandMeter:IsPlaying(StandMeter.charged) then
				StandMeter.StandMeter:Play(StandMeter.charged, true)
			end
		else
			StandMeter.StandMeter:SetFrame(StandMeter.charging, math.floor(charge / STATS.UltimateMaxCharge * 22))
		end
		StandMeter.StandMeter:Render(Vector(StandMeter.XOffset, StandMeter.YOffset), Vector(0, 0), Vector(0, 0))
		
		if not Game():IsPaused() then
			print("Updating StandMeter animation")
			StandMeter.StandMeter:Update()
		end
	end
	
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)

function mod:evaluate_cache(player,flag)

	if player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2 then

		local characterData = character
		if player:GetPlayerType() == character.Type2 then characterData = utils:TableMerge(characterData, taintedCharacter) end

		if flag == 1 then
			player.Damage = (player.Damage * character.DamageMult) + character.Damage
			if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then player.Damage = player.Damage * ITEM_MODIFIERS.BrimstonePlayerDamageMult end
		elseif flag == 8 then
			player.TearHeight = math.min(-7.5, player.TearHeight - character.Range)
		elseif flag == 16 then
			player.MoveSpeed = player.MoveSpeed + character.Speed
		end
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.evaluate_cache)


function mod:post_update()
	local player = Isaac.GetPlayer(0)
	local playerData = player:GetData()
	local controler = player.ControllerIndex

	if SETTINGS.NoShooting then
		player.FireDelay = 10
	end

	SetStand(player, stand)
	StandUpdate(player, stand, roomframes)
	StandClear(stand)

	roomframes = roomframes + 1

	--On new run, reset StandCharge
	--if Game():GetFrameCount() == 1 then 
	--	playerData[stand.Id].UltimateCharge = 0
	--	Isaac.SaveModData(mod, tostring(0))
	--end

	StandUltimate(player, stand)

	if player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2 then
		if character.VoiceA and Input.IsButtonPressed(SETTINGS.KEY_VOICE_A, controler) then
			sfx:Play(character.VoiceA,2,0,false,1)
		end
		if character.VoiceB and Input.IsButtonPressed(SETTINGS.KEY_VOICE_B, controler) then
			sfx:Play(character.VoiceB,2,0,false,1)
		end
		if character.VoiceC and Input.IsButtonPressed(SETTINGS.KEY_VOICE_C, controler) then
			sfx:Play(character.VoiceC,2,0,false,1)
		end
	end

end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.post_update)

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

function mod:onPlayerInit(player) 

	if (player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2) then
		player:EvaluateItems()
		player:AddNullCostume(character.Costume1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.onPlayerInit)

function mod:post_render()
	mod:onRender()
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.post_render)

---@param entity Entity
function mod:ChargeMeter(entity, damageAmount, damageFlags, source, countdownFrames)
	local player = Isaac.GetPlayer(0)
	local playerData = player:GetData()
	if playerData[stand.Id] and playerData[stand.Id]:Exists() and entity:IsEnemy() then
		local standData = playerData[stand.Id]:GetData()

		if SETTINGS.HasUltimate
		and standData.UltimateCharge < STATS.UltimateMaxCharge then
			standData.UltimateCharge = math.min(STATS.UltimateMaxCharge, standData.UltimateCharge + 1)
		end
	end	
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ChargeMeter)