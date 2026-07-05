local Settings = require("src/constants/settings")

local function StandClear(standDefs)
    for _, en in ipairs(Isaac.GetRoomEntities()) do
        local type = en.Type
        local variant = en.Variant

        if type == EntityType.ENTITY_FAMILIAR then
            for _, standDef in ipairs(standDefs) do
                if variant == standDef.familiarVariant and not en:GetData().linked then
                    en:Remove()
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
end

return StandClear
