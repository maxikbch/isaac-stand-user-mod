local checks = require("src/core/combat/checks")
local setStat = require("src/core/combat/set_stat")
local effects = require("src/core/combat/effects")
local ITEM_MODIFIERS = require("src/constants/item_modifiers")
local Settings = require("src/constants/settings")
local utils = require("src/utils")

local Combat = {}

Combat.checks = checks
Combat.setStat = setStat
Combat.effects = effects
Combat.ITEM_MODIFIERS = ITEM_MODIFIERS
Combat.Settings = Settings
Combat.utils = {
    Lerp = function(_, first, second, percent)
        return utils:Lerp(first, second, percent)
    end,
    VecDir = function(_, vec)
        return utils:VecDir(vec)
    end,
    AdjPos = function(_, dir, en)
        return utils:AdjPos(dir, en)
    end,
    hasbit = function(_, x, p)
        return utils:hasbit(x, p)
    end,
}

function Combat.defaultInitStandData(standData, player, standDef, standEntity)
    local STATS = standDef.stats

    standEntity.PositionOffset = standDef.floatOffset
    player:GetData().releasedir = Vector(0, 0)
    standData.tgttimer = 0
    standData.charge = player.MaxFireDelay * STATS.ChargeLength
    standData.maxcharge = player.MaxFireDelay * STATS.ChargeLength
    standData.range = 150
    standData.launchdir = Vector(0, 0)
    standData.launchto = standEntity.Position
    standData.behavior = "idle"
    standData.behaviorlast = "none"
    standData.statetime = 0
    standData.posrate = 0.08
    standData.alpha = -3
    standData.alphagoal = -3
    standData.TargetEntity = true
    standData.TargetGrid = true
end

function Combat.initStandData(standDef, standData, player, standEntity)
    if standDef.hooks and standDef.hooks.initStandData then
        standDef.hooks.initStandData(standData, player, standDef, standEntity)
        return
    end

    local behaviorModule = standDef.behaviorModule
    if type(behaviorModule) == "table" and behaviorModule.initStandData then
        behaviorModule.initStandData(standData, player, standDef, standEntity)
        return
    end

    Combat.defaultInitStandData(standData, player, standDef, standEntity)
end

function Combat.runBehaviorModule(behaviorModule, player, standDef, jsf, shootDir)
    if type(behaviorModule) == "function" then
        behaviorModule(player, standDef, jsf, shootDir)
    elseif type(behaviorModule) == "table" and behaviorModule.update then
        behaviorModule.update(player, standDef, jsf, shootDir)
    end
end

return Combat
