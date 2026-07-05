local function SetStand(player, standDef, jsf)
    if not player:HasCollectible(standDef.discItem) then
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
    end

    if player:HasCollectible(standDef.discItem) and not jsf.standState then
        jsf.standState = {}
    end
end

return SetStand
