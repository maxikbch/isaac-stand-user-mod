local standChecks = {}

---@param player EntityPlayer
---@param standEntity Entity
---@param en Entity | GridEntity
function standChecks:IsTargetable(en, player, standEntity)
	local player = Isaac.GetPlayer(0)
	local standData = standEntity:GetData()

	if en and not en.CollisionClass and en:Exists() and standData.TargetEntity then
		if
		(en.Type == EntityType.ENTITY_BOMB) then -- punch bomb
			return true
		end
	end
	return false
end

---@param player EntityPlayer
---@param standEntity Entity
---@param en Entity | GridEntity
function standChecks:CanPush(en, player, standEntity)
	return en 
		and not en.CollisionClass
		--(en.Type == 302 or -- stoney
		and en.Type == EntityType.ENTITY_BOMB and not en:GetSprite():IsPlaying("Explode") -- bomb
		--en.Type == 27 or -- host
		--en.Type == 204) -- mobile host
end

---@param player EntityPlayer
---@param standEntity Entity
---@param en Entity | GridEntity
function standChecks:IsValidEnemy(en, player, standEntity)
	local standData = standEntity:GetData()

	
	return en 
	and standData.TargetEntity
	and not en.CollisionClass
	and (((en:IsVulnerableEnemy() and en.HitPoints > 0) or standChecks:CanPush(en, player, standEntity)) 
	and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
end


---@param position Vector
---@param player EntityPlayer
---@param standEntity Entity
---@return GridEntity | nil
function standChecks:IsValidGridEntity(position, player, standEntity)
	local room = Game():GetRoom()
    local gridEntity = room:GetGridEntityFromPos(position)
	local standData = standEntity:GetData()

    if gridEntity 
	and room:GetGridIndex(position) ~= room:GetGridIndex(player.Position) 
	and standData.TargetGrid
	then
		local type = gridEntity:GetType()

        if type == GridEntityType.GRID_FIREPLACE --TODO: check this broke state
		or type == GridEntityType.GRID_TNT --TODO: check this broke state
		or (type == GridEntityType.GRID_POOP and gridEntity.State and gridEntity.State < 1000) --- 1000 is when the poop is destroyed
		then
            return gridEntity 
        end
    end
    
    return nil
end

return standChecks