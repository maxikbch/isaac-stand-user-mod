local Settings = require("src/constants/settings")
local entities = require("src/core/entities")
local entityIds = require("src/constants/entity_ids")
local targeting = require("src/core/combat/targeting")
local anim = require("src/core/combat/anim")

return function(player, standDef, jsf, shootDir)
    local playerData = player:GetData()
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local standSprite = standEntity:GetSprite()

    if standData.behavior ~= "rush" then
        return
    end

    standData.alphagoal = 1
    if standData.statetime == 0 then
        standData.launchpos = standEntity.Position
        standData.launchtgt = standData.launchto
        anim.playDir(standSprite, "Rush", standData.launchdir)
    end

    targeting.updateRushTarget(player, standDef, standEntity, standData, {
        allowGrid = Settings.TargetGridEntities,
    })

    local diff2 = standData.launchto - standEntity.Position
    standEntity.Velocity = diff2:Normalized() * math.min(25, diff2:Length())
    if diff2:Length() < 15 or (standData.tgt and standData.tgt.CollisionClass) then
        standData.behavior = "attack"
    end

    local fade = entities.Spawn(standDef, entityIds.KIND_PARTICLE, standEntity.Position, Vector(0, 0), nil)
    local fadeSprite = fade:GetSprite()
    fade.PositionOffset = standEntity.PositionOffset
    anim.playDir(fadeSprite, "Particle", standData.launchdir)
    fadeSprite.Color = Color(1, 1, 1, .25, 0, 0, 0)

    if playerData.mytgt and playerData.mytgt:Exists() then
        playerData.mytgt.Position = standData.launchto
    end
end
