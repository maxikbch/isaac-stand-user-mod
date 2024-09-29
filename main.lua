
local mod = RegisterMod("Maxo13:StandUser", 1 )

local utils = require("src/utils")
local data = require("src/data")

local OnRender = require("src/callbacks/on_render")
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OnRender)

local EvaluateCache = require("src/callbacks/evaluate_cache")
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, 
function (a, ...)
	EvaluateCache(...)
end)


local PostUpdate = require("src/callbacks/post_update")
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)


local OnUseItem = require("src/callbacks/on_use_item")
mod:AddCallback(ModCallbacks.MC_USE_ITEM, 
function (a, ...)
	OnUseItem(...)
end)


local OnRoomEnter = require("src/callbacks/on_room_enter")
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OnRoomEnter)


local OnPlayerInit = require("src/callbacks/on_player_init")
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, 
function (a, ...)
	OnPlayerInit(...)
end)


local OnEntityTakeDamage = require("src/callbacks/on_entity_take_damage")
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (a, ...)
	OnEntityTakeDamage(...)
end)


local OnNewGame = require("src/callbacks/on_new_game")
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function (a, ...)
	OnNewGame(mod)(...)
end)


local OnPickUpItem = require("src/callbacks/on_pick_up_item")
mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function (a, ...)
	OnPickUpItem(...)
end)


--save data at game exit
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, 
	function (a, ShouldSave)
		print(ShouldSave)
		if ShouldSave and not utils:RoomHasEnemies() then
			data:SavePlayersData(mod)
		end
	end)


--save data at room change
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, 
	function ()
		data:SavePlayersData(mod)
	end)

 
--load data at players init
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, 
	function ()
		data:LoadPlayersData(mod)
	end)
