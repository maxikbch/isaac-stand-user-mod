

local STATS = require("src/constants/stats")

local sounds = require("src/constants/sounds")

local standChecks = require("src/stand/checks")
local utils = require("src/utils")
local setStat = require("src/stand/set_stat")

local game = Game()
local sfx = SFXManager()

---@param player EntityPlayer
---@param shootDir Vector
return function (player, stand, shootDir)
    
	local playerData = player:GetData()	
	local standData = playerData[stand.Id]:GetData()
	local standSprite = playerData[stand.Id]:GetSprite()
	local playerPosition = player.Position

	local isRoomClear = game:GetRoom():IsClear()

    if standData.behavior == 'idle' then
		standData.alphagoal = .5
		--position
		local cdang = ((playerPosition + Vector(0, -1) - playerData[stand.Id].Position):GetAngleDegrees() + 180 % 360)
		local tgtang = player:GetHeadDirection() * 90
		if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
			tgtang = shootDir:GetAngleDegrees()
		end
		if cdang - 180 > tgtang then cdang = cdang - 360 end
		if tgtang - 180 > cdang then tgtang = tgtang - 360 end
		if playerData.shoot then standData.posrate = .2 end
		local nextang = utils:Lerp(cdang, tgtang, standData.posrate)
		standData.posrate = .08
		local nextpos = playerPosition + Vector(0, -1) + (Vector.FromAngle(nextang) * 45)

		playerData[stand.Id].Velocity = nextpos - playerData[stand.Id].Position

		--victim target
		local closedist = (-player.TearHeight * STATS.RangeMult) + 40
		local found = false
		for i, en in ipairs(Isaac.GetRoomEntities()) do
			if standChecks:IsValidEnemy(en) or standChecks:IsTargetable(en) then
				local xdif = en.Position.X - player.Position.X
				local ydif = en.Position.Y - player.Position.Y
				if playerData.releasedir.Y ~= 0 then
					if playerData.releasedir.Y * ydif > 0 and math.abs(xdif) < STATS.LockonWidth then
						if math.abs(ydif) < closedist then
							found = true
							standData.tgt = en
							closedist = math.abs(ydif)
						end
					end
				else
					if playerData.releasedir.X * xdif > 0 and math.abs(ydif) < STATS.LockonWidth then
						if math.abs(xdif) < closedist then
							found = true
							standData.tgt = en
							closedist = math.abs(xdif)
						end
					end
				end
			end
		end
		if found then
			standData.alphagoal = 1
			standData.tgttimer = 10
		elseif standData.tgttimer > 0 and (standChecks:IsValidEnemy(standData.tgt) or standChecks:IsTargetable(standData.tgt)) then
			standData.tgttimer = standData.tgttimer - 1
		else
			standData.tgt = nil
		end

		--charging up
		local maxcharge = setStat:MaxCharge(player)
		
		local faceSpriteIndex = ((player:GetHeadDirection() + 2) % 4) + 1
		local aimIndex = ((player:GetHeadDirection() + 2) % 4) + 1
		if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
			faceSpriteIndex = utils:VecDir(shootDir) + 1
			aimIndex = utils:VecDir(shootDir) + 1
		end
		if not playerData.shoot then
			if isRoomClear then
				standSprite:Play(stand.spIdle[faceSpriteIndex])
			else
				standSprite:Play(stand.spMad[faceSpriteIndex])
			end
			if standData.charge == 0 then
				standData.charge = maxcharge
				standData.behavior = 'rush'
				standData.launchdir = playerData.releasedir
				if standData.launchdir.X == 0 and standData.launchdir.Y == 0 then standData.launchdir = Vector(1, 0) end
			end
			standData.charge = math.min(maxcharge, standData.charge + (maxcharge / 90))
			standData.ready = false
			if game:GetRoom():GetFrameCount() < 1 or not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
				standData.launchto = game:GetRoom():GetClampedPosition(playerPosition + ((playerData.releasedir * standData.range) + (player:GetTearMovementInheritance(playerData.releasedir) * 10)), 20)
			end
		else
			setStat:Range(player, stand)
			standData.launchto = game:GetRoom():GetClampedPosition(playerPosition + ((playerData.releasedir * standData.range) + (player:GetTearMovementInheritance(shootDir) * 10)), 20)
			if standData.charge >0 then
				standSprite:Play(stand.spWind[aimIndex])
			elseif standSprite:IsEventTriggered("WindEnd") then
				standSprite:Play(stand.spWound[aimIndex])
			elseif standData.charge == 0 and not standData.ready then
				standSprite:Play(stand.spFlash[aimIndex])
				standData.ready = true
				sfx:Play(sounds.punchready, .35, 0, false, .98)
			elseif standSprite:IsEventTriggered("FlashEnd") then
				standSprite:Play(stand.spReady[aimIndex])
			end
			if standSprite:IsPlaying("Wound2E") or standSprite:IsPlaying("Wound2S") or standSprite:IsPlaying("Wound2W") or standSprite:IsPlaying("Wound2N") then
				standSprite:Play(stand.spWound[aimIndex])
			end
			if standSprite:IsPlaying("ReadyE") or standSprite:IsPlaying("ReadyS") or standSprite:IsPlaying("ReadyW") or standSprite:IsPlaying("ReadyN") then
				standSprite:Play(stand.spReady[aimIndex])
			end

			standData.charge = math.max(0, standData.charge - 1)
			if game:GetRoom():GetFrameCount() <= 1 then
				standData.charge = 0
			end
		end

		--idle tgt
		if playerData.mytgt and playerData.mytgt:Exists() then
			if standData.tgt then
				playerData.mytgt.Position = standData.tgt.Position
			else
				playerData.mytgt.Position = standData.launchto
			end
		end
    end
end