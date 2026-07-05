local mod = RegisterMod("Maxo13:JoJoStandFramework", 1)

local initApi = require("src/api/init")
initApi(mod)

local jsf = _G.JoJoStandFramework
local utils = require("src/utils")
local data = require("src/data")
local debug = require("src/debug")

debug:Log("Framework main loaded API v" .. tostring(jsf.API_VERSION))

local PostUpdate = require("src/callbacks/post_update")(jsf)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)

local OnRender = require("src/callbacks/on_render")(jsf)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OnRender)

local OnUseItem = require("src/callbacks/on_use_item")()
mod:AddCallback(ModCallbacks.MC_USE_ITEM, OnUseItem)

local OnRoomEnter = require("src/callbacks/on_room_enter")(jsf)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OnRoomEnter)

local OnEntityTakeDamage = require("src/callbacks/on_entity_take_damage")(jsf)
local OnNewGame = require("src/callbacks/on_new_game")(mod, jsf)
local OnPickupCollision = require("src/callbacks/on_pickup_collision")(jsf)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    jsf:EnsureLinkedStandDisc(player)
    data:LoadPlayersData(mod, jsf)
end)

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnEntityTakeDamage)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OnNewGame)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, OnPickupCollision)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, ShouldSave)
    if ShouldSave and not utils:RoomHasEnemies() then
        data:SavePlayersData(mod, jsf)
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    data:SavePlayersData(mod, jsf)
end)
