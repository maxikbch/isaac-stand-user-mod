local IdleBehavior = require("kakyoin.behaviors.idle")
local SplashBehavior = require("kakyoin.behaviors.splash")
local RushBehavior = require("kakyoin.behaviors.rush")
local RadioBehavior = require("kakyoin.behaviors.radio")
local ReturnBehavior = require("kakyoin.behaviors.return")

return function(player, standDef, jsf, shootDir)
    local standData = jsf.standEntity:GetData()

    if standData.behavior == "idle" then
        IdleBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "splash" then
        SplashBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "rush" then
        RushBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "radio" then
        RadioBehavior(player, standDef, jsf, shootDir)
    elseif standData.behavior == "return" then
        ReturnBehavior(player, standDef, jsf, shootDir)
    end
end
