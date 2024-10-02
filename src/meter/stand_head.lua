local StandHead = 
{
	sprite = Sprite(),
	heads = 'heads'
}

local centerOffset = Vector(16.45, 19.3)
local scale = 0.61

StandHead.sprite:Load("gfx/stand_user/ui/stand_head.anm2", true)
StandHead.sprite.PlaybackSpeed = 0.15
StandHead.sprite.Scale = Vector(scale, scale)

---@param offset Vector
local function RenderStandHead(offset, data)

    local sprite = StandHead.sprite

    local head = data.SelectedForm or 0

    sprite:SetFrame(StandHead.heads, head)

    sprite:Render(offset + centerOffset, Vector(0, 0), Vector(0, 0))
    
end

return RenderStandHead