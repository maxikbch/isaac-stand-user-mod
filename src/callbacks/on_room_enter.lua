
local Settings = require("src/constants/settings")
local character = require("src/constants/character")
local stand = require("src/constants/stand")

local utils = require("src/utils")

local config = Isaac.GetItemConfig()

local function ForEachPlayer(player, index)
	
	if (player:GetPlayerType() ~= character.Type and player:GetPlayerType() ~= character.Type2) then return end
	local playerData = player:GetData()
	if not playerData[stand.Id] or not playerData[stand.Id]:Exists() then
		playerData[stand.Id] = Isaac.Spawn(3, stand.Variant, 0, player.Position, Vector(0, 0), player)
	end
	local standData = playerData[stand.Id]:GetData()
	local standSprite = playerData[stand.Id]:GetSprite()

	standData.alphagoal = -2.5
	standData.alpha = -2.5
	standData.posrate = 1
	if standData.behavior ~= nil then
		standData.behavior = 'idle'
	end
	standSprite.Color = Color(1, 1, 1, -2.5, 0, 0, 0)
	playerData.usedBoxOfFriends = false

	if Settings.ReapplyCostume and (player:GetPlayerType() == character.Type) then
		player:AddNullCostume(character.Costume1)
	end

	if Settings.ReapplyCostume and (player:GetPlayerType() == character.Type2) then
		player:AddNullCostume(character.Costume2)
		local meat = config:GetCollectible(CollectibleType.COLLECTIBLE_MEAT)
		player:AddCostume(meat, false)
	end
end

local function OnRoomEnter()
	utils:ForAllPlayers(ForEachPlayer)
end

return OnRoomEnter