local debug = require("src/debug")
local entities = require("src/core/entities")
local entityIds = require("src/constants/entity_ids")
local RoomEntities = require("src/core/room_entities")

local function StandClear(standDefs, linkedHashes, roomEntities)
    local removed = 0
    linkedHashes = linkedHashes or {}
    roomEntities = roomEntities or RoomEntities.Get()

    for _, en in ipairs(roomEntities) do
        for _, standDef in ipairs(standDefs) do
            if entities.Matches(standDef, entityIds.KIND_STAND, en) then
                local hash = GetPtrHash(en)
                if not linkedHashes[hash] then
                    debug:Log(string.format(
                        "StandClear remove stand variant=%s subtype=%s frame=%s",
                        tostring(en.Variant),
                        tostring(en.SubType),
                        tostring(en.FrameCount)
                    ))
                    en:Remove()
                    removed = removed + 1
                end
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
