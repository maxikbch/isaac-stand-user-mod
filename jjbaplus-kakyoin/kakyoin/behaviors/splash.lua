local emeraldEntities = require("kakyoin.emerald_entities")
local JSF = _G.JoJoStandFramework
local setStat = JSF.Combat.setStat

local sfx = SFXManager()

local EMERALD_SPEED = 25
local MAX_PUNCHES = 30

local function spawnSplashTear(standPos, launchdir, player, standData, stats)
    local splashS = standPos + Vector(0, 20)
    local splashN = standPos - Vector(0, 20)
    local splashE = standPos - Vector(20, 0)
    local splashO = standPos + Vector(20, 0)

    if launchdir.Y == -1 then
        emeraldEntities.spawnTear(player, splashN, Vector.FromAngle(270) * EMERALD_SPEED, standData.damage or 1, stats, "ns")
    elseif launchdir.X == 1 then
        emeraldEntities.spawnTear(player, splashO, Vector.FromAngle(0) * EMERALD_SPEED, standData.damage or 1, stats, "ew")
    elseif launchdir.Y == 1 then
        emeraldEntities.spawnTear(player, splashS, Vector.FromAngle(90) * EMERALD_SPEED, standData.damage or 1, stats, "ns")
    elseif launchdir.X == -1 then
        emeraldEntities.spawnTear(player, splashE, Vector.FromAngle(180) * EMERALD_SPEED, standData.damage or 1, stats, "ew")
    end
end

local function playSplashAnim(standSprite, launchdir)
    if launchdir.Y == -1 then
        standSprite:Play("SplashN")
    elseif launchdir.X == 1 then
        standSprite:Play("SplashE")
    elseif launchdir.Y == 1 then
        standSprite:Play("SplashS")
    elseif launchdir.X == -1 then
        standSprite:Play("SplashW")
    end
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
        playSplashAnim(standSprite, standData.launchdir)
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
