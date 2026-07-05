local mod = RegisterMod("Maxo13:Jotaro", 1)

local utils = require("src/utils")
local data = require("src/data")

local OnRender = require("src/callbacks/on_render")
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OnRender)

local EvaluateCache = require("src/callbacks/evaluate_cache")
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,
	function(a, ...)
		EvaluateCache(...)
	end)


local PostUpdate = require("src/callbacks/post_update")
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)


local OnUseItem = require("src/callbacks/on_use_item")
mod:AddCallback(ModCallbacks.MC_USE_ITEM,
	function(a, ...)
		OnUseItem(...)
	end)


local OnRoomEnter = require("src/callbacks/on_room_enter")
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OnRoomEnter)


local OnPlayerInit = require("src/callbacks/on_player_init")
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,
	function(a, ...)
		OnPlayerInit(...)
	end)


local OnEntityTakeDamage = require("src/callbacks/on_entity_take_damage")
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(a, ...)
	OnEntityTakeDamage(...)
end)


local OnNewGame = require("src/callbacks/on_new_game")
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(a, ...)
	OnNewGame(mod)(...)
end)


local OnPickUpItem = require("src/callbacks/on_pick_up_item")
mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function(a, ...)
	OnPickUpItem(...)
end)


--save data at game exit
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,
	function(a, ShouldSave)
		if ShouldSave and not utils:RoomHasEnemies() then
			data:SavePlayersData(mod)
		end
	end)


--save data at room change
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,
	function()
		data:SavePlayersData(mod)
	end)


--load data at players init
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,
	function()
		data:LoadPlayersData(mod)
	end)

----stand custom callbacks

local stand = require("src/constants/stand")
local sounds = require("src/constants/sounds")
local sfx = SFXManager()
local music = MusicManager()
local STATS = require("src/constants/stats")

function mod:onShader(name)
	if name == "ZaWarudo" then
		local dist = 0
		local on = 0

		utils:ForAllPlayers(function(player, index)
			local playerData = player and player:GetData() or {}
			local standItemData = playerData[stand.Id .. ".Item"]
			if standItemData and standItemData.SuperDuration and standItemData.SuperDuration > 0 then
				local maxTime = STATS.SuperDuration
				dist = 1 / (((maxTime - 2 - standItemData.SuperDuration))) + 1 / (((standItemData.SuperDuration - 2)))
				if dist < 0 then
					dist = math.abs(dist) ^ 2
				elseif standItemData.SuperDuration - 2 == 0 or maxTime - 2 - standItemData.SuperDuration == 0 then
					dist = 1
				else
					on = 0.5
				end
				if standItemData.SuperDuration == 277 then
					sfx:Play(sounds.tick9, 5, 0, false, 1)
				elseif standItemData.SuperDuration == 157 then
					sfx:Play(sounds.tick5, 5, 0, false, 1)
				elseif standItemData.SuperDuration == 1 then
					sfx:Play(sounds.resumeTime, 2, 0, false, 1)
					music:Resume()
				elseif standItemData.SuperDuration == 0 then
					dist = 0
				end
			end
		end)

		if shaderAPI then
			shaderAPI.Shader("ZaWarudo", { DistortionScale = dist, DistortionOn = on })
		else
			return { DistortionScale = dist, DistortionOn = on }
		end
	end
end

mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.onShader)

function mod:projectileUpdate(tear)
	local source = tear.SpawnerEntity or nil
	if source then
		local player = source:ToPlayer()
		local playerData = player and player:GetData() or {}
		local standItemData = playerData[stand.Id .. ".Item"]
		if standItemData then
			if standItemData.SuperDuration == 1 then
				local data = tear:GetData()
				data.TimeFrozen = false
				tear.Velocity = data.StoredVel
				tear.FallingSpeed = data.StoredFall
				tear.FallingAccel = data.StoredAcc
			elseif standItemData.SuperDuration > 1 then
				local data = tear:GetData()
				if not data.TimeFrozen then
					data.TimeFrozen = true
					data.StoredVel = tear.Velocity
					data.StoredFall = tear.FallingSpeed
					data.StoredAcc = tear.FallingAccel
				else
					tear.Velocity = Vector(0, 0)
					tear.FallingAccel = -0.1
					tear.FallingSpeed = 0
				end
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.projectileUpdate)
