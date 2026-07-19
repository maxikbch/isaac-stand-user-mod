local character = require("{{ID}}.character_definition")
local stats = require("{{ID}}.stand_stats")

return {
    id = "{{STAND_ID}}",
    discItem = Isaac.GetItemIdByName("{{DISC_NAME}}"),
    standIndex = {{STAND_INDEX}},
    entities = {
        stand = {
            name = "{{STAND_NAME}}",
            type = 3,
            modVariant = 0,
        },
        particle = {
            name = "{{STAND_NAME}} Particle",
            type = 1000,
            modVariant = 1,
        },
    },
    floatOffset = Vector(0, -36),

    behaviorModule = _G.JoJoStandFramework.Combat.behaviors.generic,

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

    -- volume / pitch / loop live here so combat code only picks a key.
    -- ExtraSounds reuses punch/rage samples (cry_* were duplicates).
    sounds = {
        punchlight = { name = "{{SOUND_PREFIX}}_PunchLight", volume = 0.75 },
        punchheavy = { name = "{{SOUND_PREFIX}}_PunchHeavy", volume = 0.75 },
        punchready = { name = "{{SOUND_PREFIX}}_PunchReady", volume = 0.35, pitch = 0.98 },
        whoosh = { name = "{{SOUND_PREFIX}}_Whoosh", volume = 0.8 },
        rage = { name = "{{SOUND_PREFIX}}_Rage", volume = 0.75 },
        cryStart = { name = "{{SOUND_PREFIX}}_PunchHeavy", volume = 0.75 },
        cryMid = { name = "{{SOUND_PREFIX}}_PunchLight", volume = 0.75, loop = true },
        cryFinish = { name = "{{SOUND_PREFIX}}_PunchHeavy", volume = 0.75 },
        cry = { name = "{{SOUND_PREFIX}}_Rage", volume = 0.75 },
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
