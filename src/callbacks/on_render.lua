local Settings = require("src/constants/settings")
local stand = require("src/constants/stand")

local RenderMeter = require("src/meter/bar")
local RenderStandHead = require("src/meter/stand_head")
local RenderButton = require("src/meter/button")


local utils = require("src/utils")

local standItem = require("src/stand/item")

local x1 = 36
local x2 = 360
local y1 = 27
local y2 = 190

local frame = 0

local offset = {
	Player0 = Vector(x1, y1),
	Player1 = Vector(x2, y1),
	Player2 = Vector(x1, y2),
	Player3 = Vector(x2, y2),
}

local function Meter(playerData, offset, data)
	
	RenderStandHead(offset, data)
	RenderMeter(frame, playerData, offset, data, 1)
	--RenderButton(frame, playerData, offset, data, 2)
	
end
  
---@param player EntityPlayer
local function ForEachPlayer(player, index)
	
	local playerData = player:GetData()

	if Settings.HasSuper and player:HasCollectible(standItem) and playerData[stand.Id..".Item"] and offset["Player"..index] then
		Meter(playerData, offset["Player"..index], playerData[stand.Id..".Item"])
	end
end

local function onRender()
	utils:ForAllPlayers(ForEachPlayer)

	frame = frame + 1
end

return onRender