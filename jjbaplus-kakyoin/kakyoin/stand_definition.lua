local character = require("kakyoin.character_definition")
local settings = require("kakyoin.settings")
local stats = require("kakyoin.stand_stats")
local emeraldSplash = require("kakyoin.emerald_splash")

local freeSkill1 = settings.FreeSkill1 == true

return {
    id = "hierophant_green",
    discItem = Isaac.GetItemIdByName("Hierophant Green Disc"),
    standIndex = 1,
    entities = {
        stand = {
            name = "Hierophant Green",
            type = 3,
            modVariant = 0,
        },
        particle = {
            name = "Hierophant Green Particle",
            type = 1000,
            modVariant = 1,
        },
    },
    floatOffset = Vector(0, -36),

    behaviorModule = require("kakyoin.behaviors.main"),

    combat = {
        chargeReleaseBehavior = "splash",
        idleAnimMode = "idle_only",
        releasePartialCharge = "reset",
        windOnlyAtFullCharge = true,
        windAnimSuffix = "",
    },

    animations = {
        spIdle = { "IdleE", "IdleS", "IdleW", "IdleN" },
        spWind = { "WindE", "WindS", "WindW", "WindN" },
        spWound = { "WoundE", "WoundS", "WoundW", "WoundN" },
        spFlash = { "FlashE", "FlashS", "FlashW", "FlashN" },
        spReady = { "ReadyE", "ReadyS", "ReadyW", "ReadyN" },
    },

    stats = stats,

    meterGfx = {
        head = "gfx/kakyoin/ui/stand_head.anm2",
    },

    chargePools = {
        primary = {
            maxCharge = stats.SuperMaxCharge,
            gainOnHit = true,
            fillColor = Color(0 / 255, 162 / 255, 94 / 255, 1, 0, 0, 0),
            filledColor = Color(0 / 255, 201 / 255, 101 / 255, 1, 0, 0, 0),
        },
    },

    skills = {
        emerald_splash = {
            kind = "custom",
            chargePool = "primary",
            useCost = freeSkill1 and 0 or stats.SuperMaxCharge,
            cooldown = freeSkill1 and 0 or stats.SuperCooldown,
            cooldownStartsOn = "complete",
            fullChargeSounds = {
                voice = { name = "HierophantGreen_FullChargeVoice", volume = 1 },
            },
            onPress = function(ctx)
                return emeraldSplash.tryActivate(ctx)
            end,
        },
    },

    slots = {
        skill1 = {
            enabled = true,
            skill = "emerald_splash",
            requiresCharge = not freeSkill1,
            chargePool = "primary",
        },
        skill2 = {
            enabled = false,
        },
    },

    -- volume / pitch / loop live here so combat code only picks a key.
    sounds = {
        punchLight = { name = "Kakyoin_PunchLight", volume = 0.75 },
        punchHeavy = { name = "Kakyoin_PunchHeavy", volume = 0.75 },
        punchReady = { name = "Kakyoin_PunchReady", volume = 0.5, pitch = 0.98 },
        whoosh = { name = "Kakyoin_Whoosh", volume = 0.8 },
        rage = { name = "Kakyoin_Rage", volume = 0.75 },
        emeraldSplash = { name = "HierophantGreen_EmeraldSplash", volume = 1 },
        emerald = { name = "HierophantGreen_Emerald", volume = 2 },
        splash = { name = "HierophantGreen_Splash", volume = 0.8 },
        kurae = { name = "HierophantGreen_Kurae", volume = 1.2 },
        twentyMeters = { name = "HierophantGreen_20Meters", volume = 1.2 },
        emeraldoSplashuo = { name = "HierophantGreen_EmeraldoSplashuo", volume = 1.2 },
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
            local punches = standDef.stats.Punches + math.ceil((player.ShotSpeed - 1) * 4)
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
                return punches * 3
            end
            return punches
        end,
    },
}
