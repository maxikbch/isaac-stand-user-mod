local emeraldEntities = require("kakyoin.emerald_entities")
local JSF = _G.JoJoStandFramework
local setStat = JSF.Combat.setStat
local anim = JSF.Combat.anim

local sfx = SFXManager()

local EMERALD_SPEED = 25
local MAX_PUNCHES = 30

local function spawnSplashTear(standPos, launchdir, player, standData, stats)
    local origin = standPos + anim.cardinalOffset(launchdir, 20)
    local angle = anim.cardinalAngle(launchdir)
    emeraldEntities.spawnTear(
        player,
        origin,
        Vector.FromAngle(angle) * EMERALD_SPEED,
        standData.damage or 1,
        stats
    )
end

return function(player, standDef, jsf, shootDir)
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local standSprite = standEntity:GetSprite()
    local sounds = standDef.sounds
    local stats = standDef.stats

    if standData.behavior ~= "splash" then
        return
    end

    standData.alphagoal = 1

    if standData.statetime == 0 then
        if sounds.emeraldSplash then
            sfx:Play(sounds.emeraldSplash, 2, 0, false, 1)
        end
        anim.playDir(standSprite, "Splash", standData.launchdir)
        setStat:AttackAmount(player, standDef, standEntity)
        setStat:AttackDamage(player, standDef, standEntity)
        standData.maxpunches = math.min(standData.maxpunches or stats.Punches, MAX_PUNCHES)
        standData.charge = setStat:MaxCharge(player, standDef)
    end

    if standData.punches < standData.maxpunches then
        spawnSplashTear(standEntity.Position, standData.launchdir, player, standData, stats)
        standData.punches = standData.punches + 1
    end

    if standData.punches >= standData.maxpunches then
        standData.behavior = "return"
    end
end
