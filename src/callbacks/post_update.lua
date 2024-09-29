local SETTINGS = require("src/constants/settings")
local character = require("src/constants/character")
local stand = require("src/constants/stand")

local StandUpdate = require("src/stand/update")
local SetStand = require("src/stand/set")
local StandClear = require("src/stand/clear")
local StandUltimate = require("src/stand/ultimate")

local utils = require("src/utils")

local sfx = SFXManager()

local function ForEachPlayer(player, index)
	
	local controler = player.ControllerIndex
	
	if SETTINGS.NoShooting then
		player.FireDelay = 10
	end

	SetStand(player, stand)
	StandUpdate(player, stand)
	StandClear(stand)

	StandUltimate(player, stand)

	if player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2 then
		if character.VoiceA and Input.IsButtonPressed(SETTINGS.KEY_VOICE_A, controler) then
			sfx:Play(character.VoiceA,2,0,false,1)
		end
		if character.VoiceB and Input.IsButtonPressed(SETTINGS.KEY_VOICE_B, controler) then
			sfx:Play(character.VoiceB,2,0,false,1)
		end
		if character.VoiceC and Input.IsButtonPressed(SETTINGS.KEY_VOICE_C, controler) then
			sfx:Play(character.VoiceC,2,0,false,1)
		end
	end
end

local function PostUpdate()
	utils:ForAllPlayers(ForEachPlayer)
end

return PostUpdate