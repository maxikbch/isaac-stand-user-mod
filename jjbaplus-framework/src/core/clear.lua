local debug = require("src/debug")
local entities = require("src/core/entities")
local entityIds = require("src/constants/entity_ids")

local function StandClear(standDefs)
    local removed = 0

    for _, en in ipairs(Isaac.GetRoomEntities()) do
        for _, standDef in ipairs(standDefs) do
            if entities.Matches(standDef, entityIds.KIND_STAND, en) and not en:GetData().linked then
                debug:Log(string.format(
                    "StandClear remove stand variant=%s subtype=%s linked=%s frame=%s",
                    tostring(en.Variant),
                    tostring(en.SubType),
                    tostring(en:GetData().linked),
                    tostring(en.FrameCount)
                ))
                en:Remove()
                removed = removed + 1
                break
            end

            if entities.Matches(standDef, entityIds.KIND_PARTICLE, en) then
                en:GetSprite().Color = Color(1, 1, 1, .3 * (1 / en.FrameCount), 0, 0, 0)
                if en.FrameCount >= 3 then
                    en:Remove()
                end
                break
            end
        end
    end

    if removed > 0 then
        debug:Log("StandClear removed " .. tostring(removed) .. " stand(s) this frame")
    end
end

return StandClear
