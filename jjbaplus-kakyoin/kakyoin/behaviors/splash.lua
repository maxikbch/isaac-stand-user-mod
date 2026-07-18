local emeraldEntities = require("kakyoin.emerald_entities")
local JSF = _G.JoJoStandFramework
local setStat = JSF.Combat.setStat
local anim = JSF.Combat.anim

local sfx = SFXManager()

local EMERALD_SPEED = 25
local MAX_PUNCHES = 30
local FOLLOW_RATE = 0.2
local MAX_FOLLOW_SPEED = 6
--- Degrees of random yaw so the stream fans out instead of a straight line.
local ANGLE_SPREAD = 11
--- Perpendicular / forward spawn jitter (pixels).
local POSITION_JITTER = 9
local FORWARD_JITTER = 6
local DIRECTIONAL_SPAWN_OFFSETS = {
    N = Vector(0, -6),
    E = Vector(30, 0),
    S = Vector(0, 6),
    W = Vector(-30, 0),
}

local PHASE_IN = "in"
local PHASE_HOLD = "hold"
local PHASE_OUT = "out"

local function spawnSplashTear(standPos, launchdir, player, standData, stats)
    local baseAngle = anim.cardinalAngle(launchdir)
    local dirSuffix = anim.dirSuffix(launchdir)
    local angleSpread = stats.SplashAngleSpread or ANGLE_SPREAD
    local posJitter = stats.SplashPositionJitter or POSITION_JITTER
    local fwdJitter = stats.SplashForwardJitter or FORWARD_JITTER

    local angle = baseAngle + ((math.random() * 2) - 1) * angleSpread
    local lateral = ((math.random() * 2) - 1) * posJitter
    local forward = math.random() * fwdJitter
    local origin = standPos
        + anim.cardinalOffset(launchdir, 20)
        + DIRECTIONAL_SPAWN_OFFSETS[dirSuffix]
        + Vector.FromAngle(baseAngle + 90) * lateral
        + Vector.FromAngle(baseAngle) * forward

    emeraldEntities.spawnTear(
        player,
        origin,
        Vector.FromAngle(angle) * EMERALD_SPEED,
        standData.damage or 1,
        stats,
        { spectral = true }
    )
end

local function beginHold(standSprite, standData)
    anim.playDir(standSprite, "SplashHold", standData.launchdir)
    standData.splashPhase = PHASE_HOLD
end

local function beginOut(standSprite, standData)
    anim.playDir(standSprite, "SplashOut", standData.launchdir)
    standData.splashPhase = PHASE_OUT
end

local function followPlayer(player, standEntity, standData)
    standData.splashPlayerOffset = standData.splashPlayerOffset
        or (standEntity.Position - player.Position)
    local target = player.Position + standData.splashPlayerOffset
    local velocity = (target - standEntity.Position) * FOLLOW_RATE
    if velocity:Length() > MAX_FOLLOW_SPEED then
        velocity = velocity:Resized(MAX_FOLLOW_SPEED)
    end
    standEntity.Velocity = velocity
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
        if sounds.splash then
            sfx:Play(sounds.splash, 0.3, 0, false, 1)
        end
        anim.playDir(standSprite, "SplashIn", standData.launchdir)
        setStat:AttackAmount(player, standDef, standEntity)
        setStat:AttackDamage(player, standDef, standEntity)
        standData.maxpunches = math.min(standData.maxpunches or stats.Punches, MAX_PUNCHES)
        standData.charge = setStat:MaxCharge(player, standDef)
        standData.splashPhase = PHASE_IN
        standData.splashPlayerOffset = standEntity.Position - player.Position
        standEntity.Velocity = Vector.Zero
        return
    end

    followPlayer(player, standEntity, standData)

    local phase = standData.splashPhase or PHASE_IN

    if phase == PHASE_IN then
        if standSprite:IsEventTriggered("Punch") or anim.isFinishedDir(standSprite, "SplashIn") then
            beginHold(standSprite, standData)
            phase = PHASE_HOLD
        else
            return
        end
    end

    if phase == PHASE_HOLD then
        if standData.punches < standData.maxpunches then
            spawnSplashTear(standEntity.Position, standData.launchdir, player, standData, stats)
            standData.punches = standData.punches + 1
        end

        if standData.punches >= standData.maxpunches then
            beginOut(standSprite, standData)
        end
        return
    end

    if phase == PHASE_OUT and anim.isFinishedDir(standSprite, "SplashOut") then
        standData.splashPhase = nil
        standData.splashPlayerOffset = nil
        standData.behavior = "return"
    end
end
