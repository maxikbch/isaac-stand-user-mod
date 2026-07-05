local character = require("character_definition")
local stats = require("stand_stats")
local timeStop = require("time_stop")

return {
    id = "star_platinum",
    discItem = Isaac.GetItemIdByName("Star Platinum Disc"),
    familiarVariant = 13000,
    particleVariant = 13001,
    floatOffset = Vector(0, -36),

    animations = {
        spIdle = { "IdleE", "IdleS", "IdleW", "IdleN" },
        spMad = { "MadE", "MadS", "MadW", "MadN" },
        spWind = { "Wind2E", "Wind2S", "Wind2W", "Wind2N" },
        spWound = { "Wound2E", "Wound2S", "Wound2W", "Wound2N" },
        spFlash = { "FlashE", "FlashS", "FlashW", "FlashN" },
        spReady = { "ReadyE", "ReadyS", "ReadyW", "ReadyN" },
        spRush = { "RushE", "RushS", "RushW", "RushN" },
        spPunch = { "PunchE", "PunchS", "PunchW", "PunchN" },
        spOra = { "OraE", "OraS", "OraW", "OraN" },
        spParticle = { "ParticleE", "ParticleS", "ParticleW", "ParticleN" },
    },

    stats = stats,

    meterGfx = {
        bar = "gfx/jotaro/ui/meter_bar.anm2",
        buttons = "gfx/jotaro/ui/meter_buttons.anm2",
        head = "gfx/jotaro/ui/stand_head.anm2",
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
        onSuperStart = function(player, standEntity, standDef)
            timeStop.onSuperStart(player, standDef)
        end,
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
