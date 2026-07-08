local JSF = _G.JoJoStandFramework
local Combat = JSF.Combat
local targeting = Combat.targeting
local anim = Combat.anim

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
        anim.playDir(standSprite, "Idle", standData.launchdir)
    end

    targeting.updateRushTarget(player, standDef, standEntity, standData, {
        allowGrid = false,
    })

    local diff2 = standData.launchto - standEntity.Position
    standEntity.Velocity = diff2:Normalized() * math.min(25, diff2:Length())

    if diff2:Length() < 15 then
        standData.behavior = "return"
    end

    if playerData.mytgt and playerData.mytgt:Exists() then
        playerData.mytgt.Position = standData.launchto
    end
end
