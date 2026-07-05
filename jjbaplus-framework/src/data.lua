local json = require("json")
local utils = require("src/utils")

local data = {
    runContinued = false,
}

function data:Get(mod)
    if mod:HasData() then
        local saved = mod:LoadData()
        return json.decode(saved)
    end
    return nil
end

function data:GetRunSeed()
    return Game():GetSeeds():GetStartSeed()
end

function data:ShouldRestoreSession(mod)
    if not mod:HasData() then
        return false
    end

    local savedData = self:Get(mod)
    if not savedData or not savedData.runSeed or not savedData.Players then
        return false
    end

    return savedData.runSeed == self:GetRunSeed()
end

local function SavePlayerData(mod, jsf)
    return function(player, index)
        local standDef = jsf:GetActiveStand(player)
        if not standDef then
            return
        end

        local savedData = data:Get(mod) or {}
        local jsfData = jsf:GetPlayerData(player)

        savedData.runSeed = data:GetRunSeed()

        if not savedData.Players then
            savedData.Players = {}
        end

        if not savedData.Players["Player"..index] then
            savedData.Players["Player"..index] = {}
        end

        local playerSave = savedData.Players["Player"..index]
        playerSave.activeStandId = jsfData.activeStandId
        playerSave.activeDiscItem = jsfData.activeDiscItem

        if jsfData.standState then
            playerSave.standState = jsfData.standState
        end

        mod:SaveData(json.encode(savedData))
    end
end

local function LoadPlayerData(mod, jsf)
    return function(player, index)
        if not data:ShouldRestoreSession(mod) then
            return
        end

        local jsfData = jsf:GetPlayerData(player)
        local savedData = data:Get(mod)

        if savedData and savedData.Players and savedData.Players["Player"..index] then
            local playerSave = savedData.Players["Player"..index]

            if playerSave.standState then
                jsfData.standState = playerSave.standState
            end
            if playerSave.activeStandId then
                jsfData.activeStandId = playerSave.activeStandId
            end
            if playerSave.activeDiscItem then
                jsfData.activeDiscItem = playerSave.activeDiscItem
            end
        end

        local standDef = jsf:GetActiveStand(player)
        if standDef and jsfData.activeDiscItem ~= standDef.discItem then
            jsfData.activeDiscItem = standDef.discItem
        end
    end
end

function data:OnGameStarted(isContinuedGame, mod)
    self.runContinued = isContinuedGame

    if not isContinuedGame then
        mod:SaveData(json.encode({}))
    end
end

function data:IsRunContinued()
    return self.runContinued
end

function data:ResetPlayerSession(jsf, player)
    local playerData = player:GetData()
    local oldJsf = playerData.JSF
    local hadActiveSuper = oldJsf and oldJsf.standState and (oldJsf.standState.SuperDuration or 0) > 0

    playerData.JSF = {
        activeStandId = nil,
        activeDiscItem = nil,
        standEntity = nil,
        standState = {},
    }

    if hadActiveSuper then
        Music():Resume()
    end
end

function data:LoadPlayer(mod, jsf, player, index)
    LoadPlayerData(mod, jsf)(player, index)
end

function data:SavePlayersData(mod, jsf)
    utils:ForAllPlayers(SavePlayerData(mod, jsf))
end

function data:LoadPlayersData(mod, jsf)
    utils:ForAllPlayers(LoadPlayerData(mod, jsf))
end

return data
