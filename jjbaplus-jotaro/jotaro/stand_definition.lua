local character = require("jotaro.character_definition")
local stats = require("jotaro.stand_stats")
local timeStop = require("jotaro.time_stop")

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
        },
    },

    skills = {
        time_stop = {
            kind = "active",
            chargePool = "primary",
            useCost = stats.SuperMaxCharge,
            duration = stats.SuperDuration,
            cooldown = stats.SuperCooldown,
            onActivate = activateTimeStop,
            onDeactivate = deactivateTimeStop,
        },
    },

    slots = {
        skill1 = {
            enabled = true,
            skill = "time_stop",
            requiresCharge = true,
            chargePool = "primary",
        },
        skill2 = {
            enabled = false,
        },
    },

    sounds = {
        punchlight = Isaac.GetSoundIdByName("Jotaro_PunchLight"),
        punchheavy = Isaac.GetSoundIdByName("Jotaro_PunchHeavy"),
        punchready = Isaac.GetSoundIdByName("Jotaro_PunchReady"),
        whoosh = Isaac.GetSoundIdByName("Jotaro_Whoosh"),
        cryStart = Isaac.GetSoundIdByName("StarPlatinum_Cry_Start"),
        cryMid = Isaac.GetSoundIdByName("StarPlatinum_Cry_Mid"),
        cryFinish = Isaac.GetSoundIdByName("StarPlatinum_Cry_Finish"),
        cry = Isaac.GetSoundIdByName("StarPlatinum_Cry"),
        zaWarudo = Isaac.GetSoundIdByName("StarPlatinum_ZaWarudo"),
        stopTime = Isaac.GetSoundIdByName("StarPlatinum_StopTime"),
        resumeTime = Isaac.GetSoundIdByName("StarPlatinum_ResumeTime"),
        tick5 = Isaac.GetSoundIdByName("StarPlatinum_Tick5"),
        tick9 = Isaac.GetSoundIdByName("StarPlatinum_Tick9"),
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
