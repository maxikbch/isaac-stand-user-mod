local character = require("jotaro.character_definition")
local settings = require("jotaro.settings")
local stats = require("jotaro.stand_stats")
local timeStop = require("jotaro.time_stop")

local freeSkill1 = settings.FreeSkill1 == true

local function emitGlobalTimeFrozen(ctx, active)
    if ctx.framework and ctx.framework.Events then
        ctx.framework.Events.emit("global_time_frozen", {
            player = ctx.player,
            standDef = ctx.standDef,
            active = active,
        })
    end
end

local function activateTimeStop(ctx)
    emitGlobalTimeFrozen(ctx, true)
    timeStop.onActivate(ctx.player, ctx.standDef)
end

local function deactivateTimeStop(ctx)
    emitGlobalTimeFrozen(ctx, false)
    timeStop.onDeactivate()
end

return {
    id = "star_platinum",
    discItem = Isaac.GetItemIdByName("Star Platinum Disc"),
    standIndex = 0,
    entities = {
        stand = {
            name = "Star Platinum",
            type = 3,
            modVariant = 0,
        },
        particle = {
            name = "Star Platinum Particle",
            type = 1000,
            modVariant = 1,
        },
    },
    floatOffset = Vector(0, -36),

    behaviorModule = _G.JoJoStandFramework.Combat.behaviors.generic,

    animations = {
        spIdle = { "IdleE", "IdleS", "IdleW", "IdleN" },
        spMad = { "MadE", "MadS", "MadW", "MadN" },
        spWind = { "WindE", "WindS", "WindW", "WindN" },
        spWound = { "WoundE", "WoundS", "WoundW", "WoundN" },
        spFlash = { "FlashE", "FlashS", "FlashW", "FlashN" },
        spReady = { "ReadyE", "ReadyS", "ReadyW", "ReadyN" },
        spRush = { "RushE", "RushS", "RushW", "RushN" },
        spPunch = { "PunchE", "PunchS", "PunchW", "PunchN" },
        spOra = { "OraE", "OraS", "OraW", "OraN" },
        spParticle = { "ParticleE", "ParticleS", "ParticleW", "ParticleN" },
    },

    stats = stats,

    meterGfx = {
        head = "gfx/jotaro/ui/stand_head.anm2",
    },

    chargePools = {
        primary = {
            maxCharge = stats.SuperMaxCharge,
            gainOnHit = true,
            fillColor = Color(98 / 255, 42 / 255, 90 / 255, 1, 0, 0, 0),
            filledColor = Color(198 / 255, 91 / 255, 183 / 255, 1, 0, 0, 0),
        },
    },

    skills = {
        time_stop = {
            kind = "active",
            chargePool = "primary",
            useCost = freeSkill1 and 0 or stats.SuperMaxCharge,
            duration = stats.SuperDuration,
            cooldown = freeSkill1 and 0 or stats.SuperCooldown,
            fullChargeSounds = {
                voice = { name = "Jotaro_FullChargeVoice", volume = 1 },
            },
            onActivate = activateTimeStop,
            onDeactivate = deactivateTimeStop,
        },
    },

    slots = {
        skill1 = {
            enabled = true,
            skill = "time_stop",
            requiresCharge = not freeSkill1,
            chargePool = "primary",
        },
        skill2 = {
            enabled = false,
        },
    },

    -- volume / pitch / loop live here so combat code only picks a key.
    sounds = {
        punchLight = { name = "Jotaro_PunchLight", volume = 0.75 },
        punchHeavy = { name = "Jotaro_PunchHeavy", volume = 0.75 },
        punchReady = { name = "Jotaro_PunchReady", volume = 0.5, pitch = 0.98 },
        whoosh = { name = "Jotaro_Whoosh", volume = 0.8 },
        rage = { name = "Jotaro_Rage", volume = 0.75 },
        zaWarudo = { name = "StarPlatinum_ZaWarudo", volume = 1 },
        stopTime = { name = "StarPlatinum_StopTime", volume = 0.75 },
        resumeTime = { name = "StarPlatinum_ResumeTime", volume = 0.75 },
        tokiWaUgokidasu = { name = "StarPlatinum_TokiWaUgokidasu", volume = 2 },
        tick5 = { name = "StarPlatinum_Tick5", volume = 0.75 },
        tick9 = { name = "StarPlatinum_Tick9", volume = 0.75 },
    },

    linkedCharacters = {
        character.Type,
        character.Type2,
    },

    hooks = {
        getMaxPunches = function(player, standDef)
            if player:GetPlayerType() == character.Type2 then
                return standDef.stats.Punches
            end
            return standDef.stats.Punches + math.ceil((player.ShotSpeed - 1) * 4)
        end,
        getFinisherDamageMult = function(player, standDef)
            if player:GetPlayerType() == character.Type2 then
                return standDef.stats.DamageBirthrightFinisherB
            end
            return standDef.stats.DamageBirthrightFinisher
        end,
    },
}
