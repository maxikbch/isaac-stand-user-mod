
local SETTINGS = require("src/settings")
local ITEM_MODIFIERS = require("src/item_modifiers")
local character = require("src/character")
local stand = require("src/stand")

local StandUpdate = require("src/stand/update")
local SetStand = require("src/stand/set")
local StandClear = require("src/stand/clear")

local mod = RegisterMod("Maxo13:StandUser", 1 )
local _log = {}
local config = Isaac.GetItemConfig()

local taintedStandUser = {
	DamageMult = 6/7,
	Damage = 0.5,
	Speed = 0.15,
	Range = -8.75,
}

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
			if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then player.Damage = player.Damage * ITEM_MODIFIERS.BrimstonePlayerDamageMult end
		elseif flag == 8 then
			player.TearHeight = math.min(-7.5, player.TearHeight - character.Range)
		elseif flag == 16 then
			player.MoveSpeed = player.MoveSpeed + character.Speed
		end
	elseif player:GetPlayerType() == character.Type2 then
		if flag == 1 then
			player.Damage = (player.Damage * taintedStandUser.DamageMult) + taintedStandUser.Damage
			if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then player.Damage = player.Damage * ITEM_MODIFIERS.BrimstonePlayerDamageMult end
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

	if SETTINGS.NoShooting then
		player.FireDelay = 10
	end

	SetStand(player, stand)
	StandUpdate(player, stand, roomframes)
	StandClear(stand)

	roomframes = roomframes + 1

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

function mod:onPlayerInit() 
	local player = Isaac.GetPlayer(0)

	if (player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2) then
		player:EvaluateItems()
		player:AddNullCostume(character.Costume1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod:onPlayerInit())

function mod:post_render()
	mod:onRender()
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.post_render)
