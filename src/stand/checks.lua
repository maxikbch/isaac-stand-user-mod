local standChecks = {}

function standChecks:IsTargetable(en)
	local player = Isaac.GetPlayer(0)
	if en and not en.CollisionClass and en:Exists() then
		if
		(en.Type == EntityType.ENTITY_BOMB) then -- punch bomb
			return true
		end
	end
	return false
end

function standChecks:CanPush(en)
	return en 
		and not en.CollisionClass
		--(en.Type == 302 or -- stoney
		and en.Type == EntityType.ENTITY_BOMB and not en:GetSprite():IsPlaying("Explode") -- bomb
		--en.Type == 27 or -- host
		--en.Type == 204) -- mobile host
end

---comment
---@param en Entity | GridEntity
function standChecks:IsValidEnemy(en)
	return en 
	and not en.CollisionClass
	and (((en:IsVulnerableEnemy() and en.HitPoints > 0) or standChecks:CanPush(en)) 
	and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
end

function standChecks:IsValidGridEntity(position)
	local room = Game():GetRoom()
    local gridEntity = room:GetGridEntityFromPos(position)
    if gridEntity then
		local type = gridEntity:GetType()

        if (type == GridEntityType.GRID_FIREPLACE)
		or type == GridEntityType.GRID_POOP
		then
            return gridEntity 
        end
    end
    
    return nil
end

return standChecks