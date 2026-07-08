local Settings = require("src/constants/settings")
local utils = require("src/utils")
local Combat = require("src/core/combat/init")
local InputCombat = require("src/core/input_combat")
local StandVisual = require("src/core/stand_visual")

function StandUpdate(player, standDef, jsf)
    if not jsf.standEntity or not jsf.standEntity:Exists() then
        return
    end

    local playerData = player:GetData()
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()
    standData.linked = true
    local playerPosition = player.Position
    local shootDir = utils:GetShootDir(player)

    if standData.behavior == nil then
        Combat.initStandData(standDef, standData, player, standEntity)
    end

    InputCombat.updateInput(player, jsf, shootDir)

    if Settings.VisibleTarget then
        if not (playerData.mytgt and playerData.mytgt:Exists()) then
            playerData.mytgt = Isaac.Spawn(1000, 30, 0, playerPosition, Vector(0, 0), player)
            playerData.mytgt.RenderZOffset = -10000
            playerData.mytgt:GetSprite().Color = Color(191/255, 218/255, 224/255, .6, 0, 0, 0)
        end
    end

    if standData.punchtear and standData.punchtear:Exists() then
        standData.punchtear:Remove()
    end

    Combat.runBehaviorModule(standDef.behaviorModule, player, standDef, jsf, shootDir)

    StandVisual.updateStandVisual(player, standDef, standEntity, standData)
    StandVisual.updateBehaviorState(standData)
end

return StandUpdate
