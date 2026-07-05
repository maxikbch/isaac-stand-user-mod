local mod = RegisterMod("Maxo13:JJBAPlus_Framework", 1)

local initApi = require("src/api/init")
initApi(mod)

local jsf = _G.JoJoStandFramework
local utils = require("src/utils")
local data = require("src/data")
local debug = require("src/debug")

debug:Log("Framework main loaded API v" .. tostring(jsf.API_VERSION))

local OnNewGame = require("src/callbacks/on_new_game")(mod, jsf, data)
local OnEntityTakeDamage = require("src/callbacks/on_entity_take_damage")(jsf)
local OnPickupCollision = require("src/callbacks/on_pickup_collision")(jsf)
local OnRoomEnter = require("src/callbacks/on_room_enter")(jsf)
local PostUpdate = require("src/callbacks/post_update")(jsf)
local OnRender = require("src/callbacks/on_render")(jsf)
local OnUseItem = require("src/callbacks/on_use_item")()

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OnNewGame)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    local playerIndex = utils:GetPlayerIndex(player)

    data:ResetPlayerSession(jsf, player)

    if data:ShouldRestoreSession(mod) then
        data:LoadPlayer(mod, jsf, player, playerIndex)
    end

    jsf:EnsureLinkedStandDisc(player)
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OnRender)
mod:AddCallback(ModCallbacks.MC_USE_ITEM, OnUseItem)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OnRoomEnter)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnEntityTakeDamage)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, OnPickupCollision)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, ShouldSave)
    if ShouldSave and not utils:RoomHasEnemies() then
        data:SavePlayersData(mod, jsf)
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    data:SavePlayersData(mod, jsf)
end)
