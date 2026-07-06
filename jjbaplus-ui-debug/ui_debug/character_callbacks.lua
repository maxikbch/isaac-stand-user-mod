local character = require("ui_debug.character_definition")

local JSF = _G.JoJoStandFramework

local function isCharacter(player)
    local playerType = player:GetPlayerType()
    return playerType == character.Type or playerType == character.Type2
end

return function(mod, debugUi)
    local ui = debugUi(JSF)

    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
        if not isCharacter(player) then
            return
        end

        JSF:EnsureLinkedStandDisc(player)
        ui.onPlayerInit(player)
    end)

    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        local player = Isaac.GetPlayer(0)
        if not player or not player:Exists() or not isCharacter(player) then
            return
        end
        ui.onInput(player)
    end)

    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local player = Isaac.GetPlayer(0)
        if not player or not player:Exists() or not isCharacter(player) then
            return
        end
        local standDef = JSF:GetStand("ui_debug")
        if not standDef or not player:HasCollectible(standDef.discItem) then
            return
        end
        ui.renderHelp()
    end)
end
