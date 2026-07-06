local registerStandFactory = require("src/api/register_stand")
local playerStandFactory = require("src/api/player_stand")
local StandInput = require("src/core/input")

return function(mod)
    local registry = {
        stands = {},
        discToStand = {},
        characterToStand = {},
    }

    mod._registry = registry
    mod.API_VERSION = 1

    local playerApi = playerStandFactory(registry)
    local registerStand = registerStandFactory(registry)

    mod.RegisterStand = function(_, def)
        registerStand(def)
    end

    mod.GetStand = function(_, id)
        return playerApi:GetStand(id)
    end

    mod.GetActiveStand = function(_, player)
        return playerApi:GetActiveStand(player)
    end

    mod.GetActiveStandId = function(_, player)
        return playerApi:GetActiveStandId(player)
    end

    mod.IsRegisteredDisc = function(_, collectibleId)
        return playerApi:IsRegisteredDisc(collectibleId)
    end

    mod.GetPlayerData = function(_, player)
        return playerApi:GetPlayerData(player)
    end

    mod.SetActiveStand = function(_, player, standId)
        return playerApi:SetActiveStand(player, standId)
    end

    mod.SwapStandDisc = function(_, player, newDiscItem)
        return playerApi:SwapStandDisc(player, newDiscItem)
    end

    mod.EnsureLinkedStandDisc = function(_, player)
        return playerApi:EnsureLinkedStandDisc(player)
    end

    mod.GetAllStandDefs = function(_)
        return playerApi:GetAllStandDefs()
    end

    mod.OnInputUpdate = function(_)
        StandInput:OnPostUpdate()
    end

    mod.WasButtonPressedEdge = function(_, controllerIndex, button)
        return StandInput:WasButtonPressedEdge(controllerIndex, button)
    end

    mod._playerApi = playerApi

    _G.JoJoStandFramework = mod
end
