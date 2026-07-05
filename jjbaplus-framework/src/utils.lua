local LocalControllers = require("src/core/local_controllers")

local utils = {}

function utils:Lerp(first,second,percent)
	return (first + (second - first)*percent)
end

function utils:printTable(table)
	for key, value in pairs(table) do
		print(key, value)
	end
end

function utils:hasbit(x, p)
	return (x & p) == p
end

function utils:VecDir(vec)
	return(math.floor(((vec:GetAngleDegrees() % 360) / 90) + .5) % 4)
end

---@param player EntityPlayer
function utils:GetShootDir(player)
	
	local shootDir = player:GetShootingInput()

	if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) then
		if shootDir.X == 0 and shootDir.Y == 0 then
			shootDir = Vector(-1, 0):Rotated(player:GetHeadDirection() * 90)
		end
	end

	local xx = shootDir.X
	local yy = shootDir.Y
	if yy > .5 then
		yy = 1
		xx = 0
	elseif yy < -.5 then
		yy = -1
		xx = 0
	else
		yy = 0
		if xx > .5 then
			xx = 1
		elseif xx < -.5 then
			xx = -1
		else
			xx = 0
		end
	end
	shootDir = Vector(xx, yy)

	return shootDir
end
---@param en Entity | GridEntity
function utils:AdjPos(dir, en)
	return en.Position + Vector(0, 0) + (dir * ((en.Size or 0) + 45))
end

function utils:TableMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                utils:TableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end


function utils:RoomHasEnemies()
	local entities = Isaac.GetRoomEntities()
	for _, entity in ipairs(entities) do
		if entity:IsVulnerableEnemy() then
			return true
		end
	end
	return false
end


---@param player EntityPlayer
function utils:findClosestEmptyPedestal(player)
    local entities = Isaac.GetRoomEntities()
    local closestPedestal = nil
    local shortestDistance = math.huge

    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            local collectible = entity:ToPickup()
            if collectible and collectible.SubType == CollectibleType.COLLECTIBLE_NULL then
                local distance = player.Position:Distance(entity.Position)
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPedestal = entity
                end
            end
        end
    end

    return closestPedestal
end

function utils:GetAllPlayers()
    local players = {}
    local numPlayers = Game():GetNumPlayers()

    -- Loop through all the players
    for i = 0, numPlayers - 1 do
        local player = Isaac.GetPlayer(i) -- Get player by index
        table.insert(players, player) -- Add the player to the table
    end

    return players
end

---comment
---@param method function
function utils:ForAllPlayers(method)
    local numPlayers = Game():GetNumPlayers()
    for i = 0, numPlayers - 1, 1 do
        local player = Isaac.GetPlayer(i)
        if player and player:Exists() then
            method(player, i)
        end
    end
end

---@param player EntityPlayer
function utils:GetPlayerIndex(player)
    for i = 0, Game():GetNumPlayers() - 1 do
        local other = Isaac.GetPlayer(i)
        if other and other:Exists() and GetPtrHash(other) == GetPtrHash(player) then
            return i
        end
    end
    return 0
end

---@param player EntityPlayer
function utils:IsLocallyControlledPlayer(player)
    if Game():GetNumPlayers() <= 1 then
        return true
    end

    if LocalControllers:GetActiveCount() == 0 then
        return true
    end

    return LocalControllers:IsActive(player.ControllerIndex)
end

---@param player EntityPlayer
function utils:ShouldRenderStandMeter(player)
    if not player or not player:Exists() then
        return false
    end

    if player:IsCoopGhost() then
        return false
    end

    local otherTwin = player:GetOtherTwin()
    if otherTwin and player:GetPlayerType() == PlayerType.PLAYER_ESAU then
        return false
    end

    return self:IsLocallyControlledPlayer(player)
end

local METER_OFFSETS = {
    Player0 = Vector(36, 27),
    Player1 = Vector(360, 27),
    Player2 = Vector(36, 190),
    Player3 = Vector(360, 190),
}

---@param playerIndex integer
function utils:GetStandMeterScreenOffset(playerIndex)
    local numPlayers = Game():GetNumPlayers()
    if numPlayers <= 1 then
        return METER_OFFSETS.Player0
    end

    local localPlayerCount = 0
    local thisPlayerIsLocal = false

    for i = 0, numPlayers - 1 do
        local p = Isaac.GetPlayer(i)
        if p and p:Exists() and self:IsLocallyControlledPlayer(p) then
            localPlayerCount = localPlayerCount + 1
            if i == playerIndex then
                thisPlayerIsLocal = true
            end
        end
    end

    if localPlayerCount == 1 and thisPlayerIsLocal then
        return METER_OFFSETS.Player0
    end

    return METER_OFFSETS["Player" .. playerIndex]
end

return utils