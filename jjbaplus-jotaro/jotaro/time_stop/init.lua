local context = require("jotaro.time_stop.context")
local freeze = require("jotaro.time_stop.freeze")
local shader = require("jotaro.time_stop.shader")
local projectiles = require("jotaro.time_stop.projectiles")
local damageFilter = require("jotaro.time_stop.damage_filter")

local Audio = _G.JoJoStandFramework.Audio
local music = MusicManager()

local function resumeMusic()
    music:Resume()
end

return {
    onActivate = function(player, standDef)
        Audio.play(standDef.sounds.stopTime)
        Audio.play(standDef.sounds.zaWarudo)
        music:Pause()
    end,

    onDeactivate = resumeMusic,

    postUpdate = function(JSF)
        context.forEachStarPlatinumPlayer(JSF, freeze.updateTimeFreeze)
    end,

    onShader = shader.onShader,
    onProjectileUpdate = projectiles.onProjectileUpdate,
    onEntityTakeDamage = damageFilter.onEntityTakeDamage,
}
