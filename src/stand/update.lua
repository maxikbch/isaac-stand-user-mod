local STATS = require("src/constants/stats")
local SETTINGS = require("src/constants/settings")

local utils = require("src/utils")
local StandBehaviors = require("src/behaviors/main")

---@param player EntityPlayer
function StandUpdate(player, stand) 
	local playerData = player:GetData()

	--#region StandUpdate
	if playerData[stand.Id] and playerData[stand.Id]:Exists() then
		local standData = playerData[stand.Id]:GetData()
		standData.linked = true
		local standSprite = playerData[stand.Id]:GetSprite()
		local playerPosition = player.Position
		local shootDir = utils:GetShootDir(player)

		--init
		if standData.behavior == nil then
			playerData[stand.Id].PositionOffset = stand.FloatOffset
			playerData.releasedir = Vector(0, 0)
			standData.tgttimer = 0
			standData.charge = player.MaxFireDelay * STATS.ChargeLength
			standData.maxcharge = player.MaxFireDelay * STATS.ChargeLength
			standData.range = 150
			standData.launchdir = Vector(0, 0)
			standData.launchto = playerData[stand.Id].Position
			standData.behavior = 'idle'
			standData.behaviorlast = 'none'
			standData.statetime = 0
			standData.posrate = .08
			standData.alpha = -3
			standData.alphagoal = -3
			standData.UltimateCharge = 0
			standData.UltimateCooldown = 0
			standData.TargetEntity = true
			standData.TargetGrid = true
		end

		--charge input
		playerData.shootpress = false
		playerData.shootrelease = false
		if shootDir:Length() ~= 0 or Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) or player:AreOpposingShootDirectionsPressed() then
			if playerData.shoot == false then
				playerData.shootpress = true
			end
			playerData.shoot = true
			playerData.releasedir = shootDir
		else
			if playerData.shoot == true then
				playerData.shootrelease = true
			end
			playerData.shoot = false
		end

		--temp target
		if SETTINGS.VisibleTarget then
			if not (playerData.mytgt and playerData.mytgt:Exists()) then
				playerData.mytgt = Isaac.Spawn(1000, 30, 0, playerPosition, Vector(0, 0), player)
				playerData.mytgt.RenderZOffset = -10000
				playerData.mytgt:GetSprite().Color = Color(191/255, 218/255, 224/255, .6, 0, 0, 0)
			end
		end

		--float offset
		local floatbounce = 3 * Vector.FromAngle(playerData[stand.Id].FrameCount * 9).Y
		playerData[stand.Id].PositionOffset = stand.FloatOffset + Vector(0, floatbounce)

		--remove punch tear
		if standData.punchtear and standData.punchtear:Exists() then
			standData.punchtear:Remove()
		end

		StandBehaviors(player, stand, shootDir)

		--sprite alpha
		if standData.alpha < standData.alphagoal then
			standData.alpha = math.min(standData.alphagoal, standData.alpha + .35)
		elseif standData.alpha > standData.alphagoal then
			standData.alpha = math.max(standData.alphagoal, standData.alpha - .35)
		end
		if standData.alpha <= 0 then
			playerData[stand.Id]:GetSprite().Scale = Vector(0, 0)
		else
			if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
				playerData[stand.Id]:GetSprite().Scale = Vector(1.2, 1.2)
			else
				playerData[stand.Id]:GetSprite().Scale = Vector(1, 1)
			end
		end
		standSprite.Color = Color(1, 1, 1, math.max(0, standData.alpha), 0, 0, 0)

		--state timer
		if standData.behavior ~= standData.behaviorlast then
			standData.behaviorlast = standData.behavior
			standData.statetime = 0
		else
			standData.statetime = standData.statetime + 1
		end
	end
	--#endregion
	
end

return StandUpdate