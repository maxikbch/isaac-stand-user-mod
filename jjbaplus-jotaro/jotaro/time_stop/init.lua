local context = require("jotaro.time_stop.context")
local freeze = require("jotaro.time_stop.freeze")
local shader = require("jotaro.time_stop.shader")
local projectiles = require("jotaro.time_stop.projectiles")
local damageFilter = require("jotaro.time_stop.damage_filter")

local sfx = SFXManager()
local music = MusicManager()

return {
    onActivate = function(player, standDef)
        sfx:Play(standDef.sounds.stopTime, 2, 0, false, 1)
        sfx:Play(standDef.sounds.zaWarudo, 2, 0, false, 1)
        music:Disable()
    end,

    postUpdate = function(JSF)
        context.forEachStarPlatinumPlayer(JSF, freeze.updateTimeFreeze)
    end,

    onShader = shader.onShader,
    onProjectileUpdate = projectiles.onProjectileUpdate,
    onEntityTakeDamage = damageFilter.onEntityTakeDamage,
}
