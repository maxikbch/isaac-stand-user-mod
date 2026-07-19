local character = require("ui_debug.character_definition")
local stats = require("ui_debug.stand_stats")

return {
    id = "ui_debug",
    discItem = Isaac.GetItemIdByName("UI Debug Disc"),
    standIndex = -1,
    entities = {
        stand = {
            name = "UI Debug Stand",
            type = 3,
            modVariant = 0,
        },
        particle = {
            name = "UI Debug Stand Particle",
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
        secondary = {
            maxCharge = stats.AltMaxCharge,
            gainOnHit = false,
        },
    },

    skills = {
        test_active = {
            kind = "active",
            chargePool = "primary",
            useCost = stats.SuperMaxCharge,
            duration = stats.SuperDuration,
            cooldown = 0,
        },
        test_instant = {
            kind = "instant",
            chargePool = "secondary",
            useCost = stats.AltMaxCharge,
            cooldown = 0,
            fillColor = Color(1, 0.85, 0.2, 1, 0, 0, 0),
        },
        test_free = {
            kind = "instant",
            cooldown = 0,
        },
    },

    slots = {
        skill1 = {
            enabled = true,
            skill = "test_active",
            requiresCharge = true,
            chargePool = "primary",
        },
        skill2 = {
            enabled = false,
        },
    },

    sounds = {
        punchlight = { name = "Character_PunchLight", volume = 0.75 },
        punchheavy = { name = "Character_PunchHeavy", volume = 0.75 },
        punchready = { name = "Character_PunchReady", volume = 0.35, pitch = 0.98 },
        whoosh = { name = "Character_Whoosh", volume = 0.8 },
        rage = { name = "Character_Rage", volume = 0.75 },
        cryStart = { name = "Character_PunchHeavy", volume = 0.75 },
        cryMid = { name = "Character_PunchLight", volume = 0.75, loop = true },
        cryFinish = { name = "Character_PunchHeavy", volume = 0.75 },
        cry = { name = "Character_Rage", volume = 0.75 },
    },

    linkedCharacters = {
        character.Type,
        character.Type2,
    },
}
