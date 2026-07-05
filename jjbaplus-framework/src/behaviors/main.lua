local IdleBehavior = require("src/behaviors/idle")
local RushBehavior = require("src/behaviors/rush")
local AttackBehavior = require("src/behaviors/attack")
local ReturnBehavior = require("src/behaviors/return")

local function DefaultBehaviors(player, standDef, jsf, shootDir)
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()

    if standData.behavior == 'idle' then
        IdleBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == 'rush' then
        RushBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == 'attack' then
        AttackBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == 'return' then
        ReturnBehavior(player, standDef, jsf, shootDir)
    end
end

return function(player, standDef, jsf, shootDir)
    if standDef.behaviorModule then
        standDef.behaviorModule(player, standDef, jsf, shootDir)
        return
    end

    DefaultBehaviors(player, standDef, jsf, shootDir)
end
