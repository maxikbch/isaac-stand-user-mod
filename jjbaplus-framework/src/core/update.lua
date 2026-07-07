local Settings = require("src/constants/settings")
local utils = require("src/utils")
local Combat = require("src/core/combat/init")

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

    if standData.behavior == nil then
        Combat.initStandData(standDef, standData, player, standEntity)
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

    Combat.runBehaviorModule(standDef.behaviorModule, player, standDef, jsf, shootDir)

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
