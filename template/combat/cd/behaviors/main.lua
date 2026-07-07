local IdleBehavior = require("{{ID}}.behaviors.idle")
local RushBehavior = require("{{ID}}.behaviors.rush")
local AttackBehavior = require("{{ID}}.behaviors.attack")
local ReturnBehavior = require("{{ID}}.behaviors.return")

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
