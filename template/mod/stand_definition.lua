local character = require("{{ID}}.character_definition")
local stats = require("{{ID}}.stand_stats")

return {
    id = "{{STAND_ID}}",
    discItem = Isaac.GetItemIdByName("{{DISC_NAME}}"),
    familiarVariant = {{FAMILIAR_VARIANT}},
    particleVariant = {{PARTICLE_VARIANT}},
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
        head = "gfx/character/ui/stand_head.anm2",
    },

    chargePools = {
        primary = {
            maxCharge = stats.SuperMaxCharge,
            gainOnHit = true,
        },
    },

    skills = {
        -- Example active skill on skill1 (rename id and wire callbacks as needed)
        example_skill = {
            kind = "active",
            chargePool = "primary",
            useCost = stats.SuperMaxCharge,
            duration = stats.SuperDuration,
            cooldown = stats.SuperCooldown,
        },
    },

    slots = {
        skill1 = {
            enabled = true,
            skill = "example_skill",
            requiresCharge = true,
            chargePool = "primary",
        },
        skill2 = {
            enabled = false,
        },
    },

    sounds = {
        punchlight = Isaac.GetSoundIdByName("{{SOUND_PREFIX}}_PunchLight"),
        punchheavy = Isaac.GetSoundIdByName("{{SOUND_PREFIX}}_PunchHeavy"),
        punchready = Isaac.GetSoundIdByName("{{SOUND_PREFIX}}_PunchReady"),
        whoosh = Isaac.GetSoundIdByName("{{SOUND_PREFIX}}_Whoosh"),
        cryStart = Isaac.GetSoundIdByName("{{STAND_NAME_PASCAL}}_Cry_Start"),
        cryMid = Isaac.GetSoundIdByName("{{STAND_NAME_PASCAL}}_Cry_Mid"),
        cryFinish = Isaac.GetSoundIdByName("{{STAND_NAME_PASCAL}}_Cry_Finish"),
        cry = Isaac.GetSoundIdByName("{{STAND_NAME_PASCAL}}_Cry"),
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
