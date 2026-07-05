

local function StandClear(stand)
    --check entities in the room
	for i, en in ipairs(Isaac.GetRoomEntities()) do
		local type = en.Type
		local variant = en.Variant
		--remove old stand entities
		if type == 3 and variant == stand.Variant then
			if not en:GetData().linked then
				en:Remove()
			end
		end
		--particle cleanup
		if type == 1000 and variant == stand.Particle then
			en:GetSprite().Color = Color(1, 1, 1, .3 * (1 / en.FrameCount), 0, 0, 0)
			if en.FrameCount >= 3 then
				en:Remove()
			end
		end
	end
end

return StandClear