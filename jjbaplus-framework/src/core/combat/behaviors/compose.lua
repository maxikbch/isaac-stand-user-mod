local stateMachine = require("src/core/combat/behaviors/state_machine")

local function mergeStates(baseModule, overrides)
    local states = {}

    if baseModule then
        local baseStates = baseModule.states or baseModule
        if type(baseStates) == "table" then
            for name, handler in pairs(baseStates) do
                if type(handler) == "function" then
                    states[name] = handler
                end
            end
        end
    end

    for name, handler in pairs(overrides or {}) do
        states[name] = handler
    end

    return states
end

return function(config)
    config = config or {}
    local states = mergeStates(config.base, config.states)

    return {
        states = states,
        update = function(player, standDef, jsf, shootDir)
            stateMachine.run(states, player, standDef, jsf, shootDir)
        end,
    }
end
