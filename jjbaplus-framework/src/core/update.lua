local Settings = require("src/constants/settings")
local utils = require("src/utils")
local StandBehaviors = require("src/behaviors/main")

function StandUpdate(player, standDef, jsf)
    if not jsf.standEntity or not jsf.standEntity:Exists() then
        return
    end

    local playerData = player:GetData()
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    standData.linked = true
    local standSprite = standEntity:GetSprite()
    local playerPosition = player.Position
    local shootDir = utils:GetShootDir(player)
    local STATS = standDef.stats

    if standData.behavior == nil then
        standEntity.PositionOffset = standDef.floatOffset
        playerData.releasedir = Vector(0, 0)
        standData.tgttimer = 0
        standData.charge = player.MaxFireDelay * STATS.ChargeLength
        standData.maxcharge = player.MaxFireDelay * STATS.ChargeLength
        standData.range = 150
        standData.launchdir = Vector(0, 0)
        standData.launchto = standEntity.Position
        standData.behavior = 'idle'
        standData.behaviorlast = 'none'
        standData.statetime = 0
        standData.posrate = .08
        standData.alpha = -3
        standData.alphagoal = -3
        standData.TargetEntity = true
        standData.TargetGrid = true
    end

    playerData.shootpress = false
    playerData.shootrelease = false
    if shootDir:Length() ~= 0 or Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) or player:AreOpposingShootDirectionsPressed() then
        if playerData.shoot == false then
            playerData.shootpress = true
        end
        playerData.shoot = true
        playerData.releasedir = shootDir
    else
        if playerData.shoot == true then
            playerData.shootrelease = true
        end
        playerData.shoot = false
    end

    if Settings.VisibleTarget then
        if not (playerData.mytgt and playerData.mytgt:Exists()) then
            playerData.mytgt = Isaac.Spawn(1000, 30, 0, playerPosition, Vector(0, 0), player)
            playerData.mytgt.RenderZOffset = -10000
            playerData.mytgt:GetSprite().Color = Color(191/255, 218/255, 224/255, .6, 0, 0, 0)
        end
    end

    local floatbounce = 3 * Vector.FromAngle(standEntity.FrameCount * 9).Y
    standEntity.PositionOffset = standDef.floatOffset + Vector(0, floatbounce)

    if standData.punchtear and standData.punchtear:Exists() then
        standData.punchtear:Remove()
    end

    StandBehaviors(player, standDef, jsf, shootDir)

    if standData.alpha < standData.alphagoal then
        standData.alpha = math.min(standData.alphagoal, standData.alpha + .35)
    elseif standData.alpha > standData.alphagoal then
        standData.alpha = math.max(standData.alphagoal, standData.alpha - .35)
    end
    if standData.alpha <= 0 then
        standSprite.Scale = Vector(0, 0)
    else
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
            standSprite.Scale = Vector(1.2, 1.2)
        else
            standSprite.Scale = Vector(1, 1)
        end
    end
    standSprite.Color = Color(1, 1, 1, math.max(0, standData.alpha), 0, 0, 0)

    if standData.behavior ~= standData.behaviorlast then
        standData.behaviorlast = standData.behavior
        standData.statetime = 0
    else
        standData.statetime = standData.statetime + 1
    end
end

return StandUpdate
