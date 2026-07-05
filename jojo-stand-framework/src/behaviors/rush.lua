local standChecks = require("src/core/checks")
local utils = require("src/utils")
local Settings = require("src/constants/settings")

return function(player, standDef, jsf, shootDir)
    local playerData = player:GetData()
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local standSprite = standEntity:GetSprite()

    if standData.behavior ~= 'rush' then
        return
    end

    standData.alphagoal = 1
    if standData.statetime == 0 then
        standData.launchpos = standEntity.Position
        standData.launchtgt = standData.launchto
        if standData.launchdir.Y == -1 then
            standSprite:Play("RushN")
        elseif standData.launchdir.X == 1 then
            standSprite:Play("RushE")
        elseif standData.launchdir.Y == 1 then
            standSprite:Play("RushS")
        elseif standData.launchdir.X == -1 then
            standSprite:Play("RushW")
        else
            standSprite:Play("RushW")
        end
    end

    for _, en in ipairs(Isaac.GetRoomEntities()) do
        if standChecks:IsValidEnemy(en, player, standEntity) then
            local dest = utils:AdjPos(-standData.launchdir, en)
            local diff = standEntity.Position - dest
            if diff:Length() < 45 and diff:Length() < (standEntity.Position - standData.launchto):Length() then
                standData.tgt = en
                standData.launchto = dest
            end
        end
    end

    if not (standChecks:IsValidEnemy(standData.tgt, player, standEntity) or standChecks:IsTargetable(standData.tgt, player, standEntity)) then
        standData.tgt = nil
    end
    if not standData.tgt and Settings.TargetGridEntities then
        local frontGrid = standData.launchdir * 50
        local gridEntity = standChecks:IsValidGridEntity(standEntity.Position + frontGrid, player, standEntity)
        if gridEntity then
            standData.tgt = gridEntity
        end
    end

    if standData.tgt then
        local dest2 = utils:AdjPos(-standData.launchdir, standData.tgt)
        standData.launchto = dest2
    else
        standData.launchto = standData.launchtgt
    end

    local diff2 = standData.launchto - standEntity.Position
    standEntity.Velocity = diff2:Normalized() * math.min(25, diff2:Length())
    if diff2:Length() < 15 or (standData.tgt and standData.tgt.CollisionClass) then
        standData.behavior = 'attack'
    end

    local fade = Isaac.Spawn(1000, standDef.particleVariant, 0, standEntity.Position, Vector(0, 0), nil)
    local fadeSprite = fade:GetSprite()
    fade.PositionOffset = standEntity.PositionOffset
    if standData.launchdir.Y == -1 then
        fadeSprite:Play("ParticleN")
    elseif standData.launchdir.X == 1 then
        fadeSprite:Play("ParticleE")
    elseif standData.launchdir.Y == 1 then
        fadeSprite:Play("ParticleS")
    elseif standData.launchdir.X == -1 then
        fadeSprite:Play("ParticleW")
    end
    fadeSprite.Color = Color(1, 1, 1, .25, 0, 0, 0)

    if playerData.mytgt and playerData.mytgt:Exists() then
        playerData.mytgt.Position = standData.launchto
    end
end
