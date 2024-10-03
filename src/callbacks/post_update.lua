local Settings = require("src/constants/settings")
local stand = require("src/constants/stand")

local StandUpdate = require("src/stand/update")
local SetStand = require("src/stand/set")
local StandClear = require("src/stand/clear")
local StandSuper = require("src/stand/super")

local utils = require("src/utils")

local function ForEachPlayer(player, index)
	
	if Settings.NoShooting then
		player.FireDelay = 10
	end

	SetStand(player, stand)
	StandUpdate(player, stand)
	StandClear(stand)

	StandSuper(player, stand)
end

local function PostUpdate()
	utils:ForAllPlayers(ForEachPlayer)
end

return PostUpdate