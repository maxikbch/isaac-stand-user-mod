local IdleBehavior = require("src/core/combat/behaviors/generic/idle")
local RushBehavior = require("src/core/combat/behaviors/generic/rush")
local AttackBehavior = require("src/core/combat/behaviors/generic/attack")
local ReturnBehavior = require("src/core/combat/behaviors/generic/return")

return function(player, standDef, jsf, shootDir)
    local standData = jsf.standEntity:GetData()

    if standData.behavior == "idle" then
        IdleBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "rush" then
        RushBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "attack" then
        AttackBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "return" then
        ReturnBehavior(player, standDef, jsf, shootDir)
    end
end
