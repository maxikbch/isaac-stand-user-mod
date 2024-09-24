
local setStat = {}
local character = require("src/character")
local STATS = require("src/stand/stats")
local ITEM_MODIFIERS = require("src/item_modifiers")

---@param player EntityPlayer
function setStat:AttackAmount(player, stand)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	standData.punches = 0
	if player:GetPlayerType() ~= character.Type2 then
		standData.maxpunches = STATS.Punches + math.ceil((player.ShotSpeed - 1) * 4 )
	else
		standData.maxpunches = STATS.Punches
	end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then standData.maxpunches = standData.maxpunches + ITEM_MODIFIERS.PunchesPerExtraShot end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then standData.maxpunches = standData.maxpunches + (ITEM_MODIFIERS.PunchesPerExtraShot * 3) end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) then standData.maxpunches = standData.maxpunches + (ITEM_MODIFIERS.PunchesPerExtraShot * 2) end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then standData.maxpunches = standData.maxpunches * ITEM_MODIFIERS.SoyMilkPunchesMult end
		if player:GetData().usedbox then standData.maxpunches = standData.maxpunches * ITEM_MODIFIERS.BoxOfFriendsPunchesMult end
end

---@param player EntityPlayer
function setStat:AttackDamage(player, stand)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	standData.damage = 1
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then standData.damage = standData.damage * ITEM_MODIFIERS.BFFDamageBonus end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_PARASITE) then standData.damage = standData.damage * ITEM_MODIFIERS.ParasiteDamageMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY) then standData.damage = standData.damage * ITEM_MODIFIERS.CricketsBodyDamageMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then standData.damage = standData.damage * ITEM_MODIFIERS.IpecacDamageMod end
end

return setStat