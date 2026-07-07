local ITEM_MODIFIERS = require("kakyoin.item_modifiers")
local character = require("kakyoin.character_definition")

local setStat = {}

function setStat:MaxCharge(player, standDef)
    local STATS = standDef.stats
    local maxcharge = player.MaxFireDelay * STATS.ChargeLength

    if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
        maxcharge = maxcharge * ITEM_MODIFIERS.ChocolateMilkChargeMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
        maxcharge = maxcharge * ITEM_MODIFIERS.BrimstoneChargeMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then
        maxcharge = maxcharge * ITEM_MODIFIERS.EpicFetusChargeMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then
        maxcharge = maxcharge * ITEM_MODIFIERS.IpecacChargeMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then
        maxcharge = maxcharge * ITEM_MODIFIERS.MonstrosLungChargeMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
        maxcharge = ITEM_MODIFIERS.DrFetusChargeMax
    end

    return maxcharge
end

function setStat:Range(player, standDef, standEntity)
    local STATS = standDef.stats
    local standData = standEntity:GetData()

    standData.range = -player.TearHeight * STATS.RangeMult
    if player:HasCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS) then
        standData.range = standData.range * ITEM_MODIFIERS.ProptosisRangeMult
    end
    standData.range = math.max(standData.range, STATS.MinimumRange)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        standData.range = standData.range + ITEM_MODIFIERS.LudovicoRangeBonus
    end
end

function setStat:AttackAmount(player, standDef, standEntity)
    local standData = standEntity:GetData()
    local STATS = standDef.stats

    standData.punches = 0
    if standDef.hooks and standDef.hooks.getMaxPunches then
        standData.maxpunches = standDef.hooks.getMaxPunches(player, standDef)
    else
        standData.maxpunches = STATS.Punches + math.ceil((player.ShotSpeed - 1) * 4)
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then
        standData.maxpunches = standData.maxpunches + ITEM_MODIFIERS.PunchesPerExtraShot
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then
        standData.maxpunches = standData.maxpunches + (ITEM_MODIFIERS.PunchesPerExtraShot * 3)
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) then
        standData.maxpunches = standData.maxpunches + (ITEM_MODIFIERS.PunchesPerExtraShot * 2)
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then
        standData.maxpunches = standData.maxpunches * ITEM_MODIFIERS.SoyMilkPunchesMult
    end
    if player:GetData().usedBoxOfFriends then
        standData.maxpunches = standData.maxpunches * ITEM_MODIFIERS.BoxOfFriendsPunchesMult
    end
end

function setStat:AttackDamage(player, standDef, standEntity)
    local standData = standEntity:GetData()

    standData.damage = 1
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
        standData.damage = standData.damage * ITEM_MODIFIERS.BFFDamageBonus
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_PARASITE) then
        standData.damage = standData.damage * ITEM_MODIFIERS.ParasiteDamageMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY) then
        standData.damage = standData.damage * ITEM_MODIFIERS.CricketsBodyDamageMult
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then
        standData.damage = standData.damage * ITEM_MODIFIERS.IpecacDamageMod
    end
end

return setStat
