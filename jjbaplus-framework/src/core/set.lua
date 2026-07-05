local debug = require("src/debug")

local function SetStand(player, standDef, jsf)
    if not player:HasCollectible(standDef.discItem) then
        debug:LogEvery(120, "setStandNoDisc", "SetStand skip: missing disc " .. tostring(standDef.discItem))
        if jsf.standEntity and jsf.standEntity:Exists() then
            jsf.standEntity:Remove()
            jsf.standEntity = nil
        end
        if player:GetData().mytgt and player:GetData().mytgt:Exists() then
            player:GetData().mytgt:Remove()
            player:GetData().mytgt = nil
        end
        return
    end

    if player:HasCollectible(standDef.discItem) and (not jsf.standEntity or not jsf.standEntity:Exists()) then
        local standEntity = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, standDef.familiarVariant, 0, player.Position, Vector(0, 0), player)
        jsf.standEntity = standEntity
        standEntity.Parent = player
        standEntity:GetData().linked = true
        debug:Log(string.format(
            "SetStand spawned variant=%s type=%s exists=%s idx=%s",
            tostring(standDef.familiarVariant),
            tostring(standEntity.Type),
            tostring(standEntity:Exists()),
            tostring(standEntity.InitSeed or "na")
        ))
    elseif jsf.standEntity and jsf.standEntity:Exists() then
        jsf.standEntity:GetData().linked = true
        debug:LogEvery(120, "setStandKeep", string.format(
            "SetStand keep entity variant=%s alpha=%s behavior=%s",
            tostring(jsf.standEntity.Variant),
            tostring(jsf.standEntity:GetData().alpha),
            tostring(jsf.standEntity:GetData().behavior)
        ))
    else
        debug:LogEvery(60, "setStandBrokenRef", "SetStand has disc but standEntity ref missing/invalid")
    end

    if player:HasCollectible(standDef.discItem) and not jsf.standState then
        jsf.standState = {}
    end
end

return SetStand
