local ITEM_MODIFIERS = require("src/constants/item_modifiers")
local character = require("src/constants/character")
local taintedCharacter = require("src/constants/tainted_character")

local utils = require("src/utils")

local function EvaluateCache(player,flag)
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

return EvaluateCache