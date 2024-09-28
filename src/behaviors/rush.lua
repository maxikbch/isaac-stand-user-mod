
local standChecks = require("src/stand/checks")
local utils = require("src/utils")
local SETTINGS = require("src/constants/settings")

---@param player EntityPlayer
return function (player, stand, shootDir, roomframes)
    local playerData = player:GetData()
    ---@type Entity
    local standEntity = playerData[stand.Id]
	local standData = standEntity:GetData()
	local standSprite = playerData[stand.Id]:GetSprite()

    if standData.behavior == 'rush' then
        standData.alphagoal = 1
        --init rush
        if standData.statetime == 0 then
            standData.launchpos = playerData[stand.Id].Position
            standData.launchtgt = standData.launchto
            if standData.launchdir.Y == -1 then
                standSprite:Play("RushN")
            elseif standData.launchdir.X == 1 then
                standSprite:Play("RushE")
            elseif standData.launchdir.Y == 1 then
                standSprite:Play("RushS")
            elseif standData.launchdir.X == -1 then
                standSprite:Play("RushW")
            else
                standSprite:Play("RushW")
            end
        end
        --intercept target
        for i, en in ipairs(Isaac.GetRoomEntities()) do
            if standChecks:IsValidEnemy(en) then
                local dest = utils:AdjPos(-standData.launchdir, en)
                local diff = playerData[stand.Id].Position - dest
                if diff:Length() < 45 and diff:Length() < (playerData[stand.Id].Position - standData.launchto):Length() then
                    standData.tgt = en
                    standData.launchto = dest
                end
            end
        end
        --engage target
        if not (standChecks:IsValidEnemy(standData.tgt) or standChecks:IsTargetable(standData.tgt)) then
            standData.tgt = nil
        end
		if not standData.tgt and SETTINGS.TargetGridEntities then 
            local gridEntity = standChecks:IsValidGridEntity(standEntity.Position)
            if gridEntity then 
                standData.tgt = gridEntity
            end
		end

        if standData.tgt then
            local dest2 = utils:AdjPos(-standData.launchdir, standData.tgt)
            standData.launchto = dest2
        else
            standData.launchto = standData.launchtgt
        end
        --velocity
        local diff2 = standData.launchto - playerData[stand.Id].Position
        playerData[stand.Id].Velocity = diff2:Normalized() * math.min(25, diff2:Length())
        if diff2:Length() < 15 or (standData.tgt and standData.tgt.CollisionClass) then
            if standData.tgt then
                standData.behavior = 'attack'
            else
                standData.behavior = 'attack'
            end
        end
    
        local fade = Isaac.Spawn(1000, stand.Particle, 0, playerData[stand.Id].Position, Vector(0, 0), nil)
        local fadeSprite = fade:GetSprite()
        fade.PositionOffset = playerData[stand.Id].PositionOffset
        if standData.launchdir.Y == -1 then
            fadeSprite:Play("ParticleN")
        elseif standData.launchdir.X == 1 then
            fadeSprite:Play("ParticleE")
        elseif standData.launchdir.Y == 1 then
            fadeSprite:Play("ParticleS")
        elseif standData.launchdir.X == -1 then
            fadeSprite:Play("ParticleW")
        end
        fadeSprite.Color = Color(1, 1, 1, .25, 0, 0, 0)
    
        if playerData.mytgt and playerData.mytgt:Exists() then
            playerData.mytgt.Position = standData.launchto
        end
    end
end