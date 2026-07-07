local standChecks = require("kakyoin.stand_checks")
local utils = require("kakyoin.utils")

local sfx = SFXManager()

return function(player, standDef, jsf, shootDir)
    local playerData = player:GetData()
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local standSprite = standEntity:GetSprite()
    local sounds = standDef.sounds

    if standData.behavior ~= "rush" then
        return
    end

    standData.alphagoal = 1

    if standData.statetime == 0 then
        standData.launchpos = standEntity.Position
        standData.launchtgt = standData.launchto
        if sounds.emerald then
            sfx:Play(sounds.emerald, 2, 0, false, 1)
        end
        if standData.launchdir.Y == -1 then
            standSprite:Play("IdleN")
        elseif standData.launchdir.X == 1 then
            standSprite:Play("IdleE")
        elseif standData.launchdir.Y == 1 then
            standSprite:Play("IdleS")
        elseif standData.launchdir.X == -1 then
            standSprite:Play("IdleW")
        else
            standSprite:Play("IdleW")
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

    if standData.tgt then
        standData.launchto = utils:AdjPos(-standData.launchdir, standData.tgt)
    else
        standData.launchto = standData.launchtgt
    end

    local diff2 = standData.launchto - standEntity.Position
    standEntity.Velocity = diff2:Normalized() * math.min(25, diff2:Length())

    if diff2:Length() < 15 then
        if standData.superRush then
            standData.superRush = false
            if standData.tgt then
                standData.behavior = "radio"
                standData.radioFrames = standDef.stats.RadioBurstFrames
            else
                standData.behavior = "idle"
            end
        else
            standData.behavior = "return"
        end
    end

    if playerData.mytgt and playerData.mytgt:Exists() then
        playerData.mytgt.Position = standData.launchto
    end
end
