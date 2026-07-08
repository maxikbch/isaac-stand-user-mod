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
        },
    },

    skills = {
        emerald_splash = {
            kind = "custom",
            chargePool = "primary",
            useCost = freeSkill1 and 0 or stats.SuperMaxCharge,
            cooldown = freeSkill1 and 0 or stats.SuperCooldown,
            cooldownStartsOn = "complete",
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

    sounds = {
        punchlight = Isaac.GetSoundIdByName("Kakyoin_PunchLight"),
        punchheavy = Isaac.GetSoundIdByName("Kakyoin_PunchHeavy"),
        punchready = Isaac.GetSoundIdByName("Kakyoin_PunchReady"),
        whoosh = Isaac.GetSoundIdByName("Kakyoin_Whoosh"),
        rage = Isaac.GetSoundIdByName("Kakyoin_Rage"),
        cryStart = Isaac.GetSoundIdByName("HierophantGreen_Cry_Start"),
        cryMid = Isaac.GetSoundIdByName("HierophantGreen_Cry_Mid"),
        cryFinish = Isaac.GetSoundIdByName("HierophantGreen_Cry_Finish"),
        cry = Isaac.GetSoundIdByName("HierophantGreen_Cry"),
        emeraldSplash = Isaac.GetSoundIdByName("HierophantGreen_EmeraldSplash"),
        emerald = Isaac.GetSoundIdByName("HierophantGreen_Emerald"),
        splash = Isaac.GetSoundIdByName("HierophantGreen_Splash"),
        kurae = Isaac.GetSoundIdByName("HierophantGreen_Kurae"),
        twentyMeters = Isaac.GetSoundIdByName("HierophantGreen_20Meters"),
        emeraldoSplashuo = Isaac.GetSoundIdByName("HierophantGreen_EmeraldoSplashuo"),
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
