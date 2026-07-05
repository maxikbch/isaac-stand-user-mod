local StandHead =
{
    heads = 'heads'
}

local centerOffset = Vector(16.45, 19.3)
local scale = 0.61

local DEFAULT_HEAD = "gfx/stand_framework/ui/stand_head.anm2"
local sprites = {}

local function getSprite(headPath)
    if not sprites[headPath] then
        local sprite = Sprite()
        sprite:Load(headPath, true)
        sprite.PlaybackSpeed = 0.15
        sprite.Scale = Vector(scale, scale)
        sprites[headPath] = sprite
    end
    return sprites[headPath]
end

return function(offset, data, meterGfx)
    local headPath = (meterGfx and meterGfx.head) or DEFAULT_HEAD
    local sprite = getSprite(headPath)
    local head = data.SelectedForm or 0

    sprite:SetFrame(StandHead.heads, head)
    sprite:Render(offset + centerOffset, Vector(0, 0), Vector(0, 0))
end
