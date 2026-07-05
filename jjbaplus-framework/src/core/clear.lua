local debug = require("src/debug")

local function StandClear(standDefs)
    local removed = 0

    for _, en in ipairs(Isaac.GetRoomEntities()) do
        local type = en.Type
        local variant = en.Variant

        if type == EntityType.ENTITY_FAMILIAR then
            for _, standDef in ipairs(standDefs) do
                if variant == standDef.familiarVariant and not en:GetData().linked then
                    debug:Log(string.format(
                        "StandClear remove familiar variant=%s linked=%s frame=%s",
                        tostring(variant),
                        tostring(en:GetData().linked),
                        tostring(en.FrameCount)
                    ))
                    en:Remove()
                    removed = removed + 1
                    break
                end
            end
        end

        if type == 1000 then
            for _, standDef in ipairs(standDefs) do
                if variant == standDef.particleVariant then
                    en:GetSprite().Color = Color(1, 1, 1, .3 * (1 / en.FrameCount), 0, 0, 0)
                    if en.FrameCount >= 3 then
                        en:Remove()
                    end
                    break
                end
            end
        end
    end

    if removed > 0 then
        debug:Log("StandClear removed " .. tostring(removed) .. " familiar(s) this frame")
    end
end

return StandClear
