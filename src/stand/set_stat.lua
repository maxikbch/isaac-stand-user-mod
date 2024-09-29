
local setStat = {}
local character = require("src/constants/character")
local STATS = require("src/constants/stats")
local ITEM_MODIFIERS = require("src/constants/item_modifiers")
local SETTINGS = require("src/constants/settings")

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
		if player:GetData().usedBoxOfFriends then standData.maxpunches = standData.maxpunches * ITEM_MODIFIERS.BoxOfFriendsPunchesMult end
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

---@param player EntityPlayer
function setStat:MaxCharge(player)
	local maxcharge = player.MaxFireDelay * STATS.ChargeLength
	if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then maxcharge = maxcharge * ITEM_MODIFIERS.ChocolateMilkChargeMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then maxcharge = maxcharge * ITEM_MODIFIERS.BrimstoneChargeMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then maxcharge = maxcharge * ITEM_MODIFIERS.EpicFetusChargeMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then maxcharge = maxcharge * ITEM_MODIFIERS.IpecacChargeMult end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then maxcharge = maxcharge * ITEM_MODIFIERS.MonstrosLungChargeMult end
	if SETTINGS.NoShooting then maxcharge = maxcharge * ITEM_MODIFIERS.NoShootingChargeMult end
	--if player:HasCollectible(52) then maxcharge = bal.DrFetusChargeMax end

	return maxcharge
end

---@param player EntityPlayer
function setStat:Range(player, stand)
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()
	standData.range = -player.TearHeight * STATS.RangeMult
	if player:HasCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS) then standData.range = standData.range * ITEM_MODIFIERS.ProptosisRangeMult end
	standData.range = math.max(standData.range, STATS.MinimumRange)
	if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then standData.range = standData.range + ITEM_MODIFIERS.LudovicoRangeBonus end
end

return setStat