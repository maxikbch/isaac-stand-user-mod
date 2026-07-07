local emeraldEntities = require("kakyoin.emerald_entities")
local emeraldSplash = require("kakyoin.emerald_splash")

local sfx = SFXManager()

local EMERALD_SPEED = 25
local RADIO_RADIUS = 200
local vec = emeraldEntities.vecFromAngle

local RADIO_BURST = {
    { kinds = { "d1", "ns", "d2" }, angles = { 75, 90, 105 } },
    { kinds = { "d1", "ns", "d2" }, angles = { 345, 0, 15 } },
    { kinds = { "d1", "ns", "d2" }, angles = { 255, 270, 285 } },
    { kinds = { "d1", "ns", "d2" }, angles = { 165, 180, 195 } },
}

local function spawnRadioBurst(origin, player, standData, stats)
    local origins = {
        Vector(0, -RADIO_RADIUS),
        Vector(-RADIO_RADIUS, 0),
        Vector(0, RADIO_RADIUS),
        Vector(RADIO_RADIUS, 0),
    }

    for i, burst in ipairs(RADIO_BURST) do
        local basePos = origin + origins[i]
        for j, angle in ipairs(burst.angles) do
            emeraldEntities.spawnTear(
                player,
                basePos,
                vec(angle, EMERALD_SPEED),
                standData.damage or 1,
                stats,
                burst.kinds[j]
            )
        end
    end
end

return function(player, standDef, jsf, shootDir)
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    local sounds = standDef.sounds
    local stats = standDef.stats

    if standData.behavior ~= "radio" then
        return
    end

    if not standData.radioEntity or not standData.radioEntity:Exists() then
        standData.radioEntity = emeraldEntities.spawnRadioEffect(standEntity.Position)
        standData.radioOrigin = standEntity.Position
        if not standData.damage then
            standData.damage = 1
        end
        if sounds.splash then
            sfx:Play(sounds.splash, 2, 0, false, 1)
        end
    end

    standData.alphagoal = -100

    if standData.radioFrames and standData.radioFrames > 0 then
        spawnRadioBurst(standData.radioOrigin, player, standData, stats)
        standData.radioFrames = standData.radioFrames - 1
    else
        if standData.radioEntity and standData.radioEntity:Exists() then
            standData.radioEntity:Remove()
        end
        standData.radioEntity = nil
        standData.radioOrigin = nil
        standData.behavior = "return"
        emeraldSplash.onSuperComplete(player, jsf)
    end
end
