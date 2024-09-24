local standChecks = {}

function standChecks:IsTargetable(en)
	local player = Isaac.GetPlayer(0)
	if en and en:Exists() then
		if
		(en.Type == EntityType.ENTITY_BOMB) then -- punch bomb
			return true
		end
	end
	return false
end

function standChecks:CanPush(en)
	return en and
		--(en.Type == 302 or -- stoney
		en.Type == EntityType.ENTITY_BOMB and not en:GetSprite():IsPlaying("Explode") -- bomb
		--en.Type == 27 or -- host
		--en.Type == 204) -- mobile host
end

function standChecks:IsValidEnemy(en)
	return en and ((en:IsVulnerableEnemy() and en.HitPoints > 0) or standChecks:CanPush(en)) and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

return standChecks