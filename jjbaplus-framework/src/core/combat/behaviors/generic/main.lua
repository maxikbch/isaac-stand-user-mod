local stateMachine = require("src/core/combat/behaviors/state_machine")

local states = {
    idle = require("src/core/combat/behaviors/generic/idle"),
    rush = require("src/core/combat/behaviors/generic/rush"),
    attack = require("src/core/combat/behaviors/generic/attack"),
    ["return"] = require("src/core/combat/behaviors/generic/return"),
}

return {
    states = states,
    update = function(player, standDef, jsf, shootDir)
        stateMachine.run(states, player, standDef, jsf, shootDir)
    end,
}
