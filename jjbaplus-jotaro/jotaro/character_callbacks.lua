local character = require("jotaro.character_definition")
local settings = require("jotaro.settings")
local timeStop = require("jotaro.time_stop")

local JSF = _G.JoJoStandFramework

return function(mod)
    JSF.Character.registerCallbacks(mod, {
        character = character,
        settings = settings,
        hooks = {
            onPostUpdate = function()
                timeStop.postUpdate(JSF)
            end,
            onGetShaderParams = function(name)
                return timeStop.onShader(name, JSF)
            end,
            onPostProjectileUpdate = function(projectile)
                timeStop.onProjectileUpdate(projectile, JSF)
            end,
            onEntityTakeDamage = function(entity, damageAmount, damageFlags, source, countdownFrames)
                return timeStop.onEntityTakeDamage(entity, damageFlags, source, JSF)
            end,
        },
    })
end
