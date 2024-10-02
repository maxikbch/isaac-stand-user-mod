
local Button = 
{
	charging = 'charging',
	charged = 'charged',
	frames = 22
}

local ButtonType = {"super - ", "power - ", "shift - "}

local STATS = require("src/constants/stats")

local centerOffset = Vector(8.5, 34)
local secondaryOffset = Vector(0, 15)

---@param offset Vector
---@param type number
local function RenderButton(frame, playerData, offset, data, type --[[type: {1="super",2="power",3="shift} do not repeat,]], forMeter --[[forMether: only for button in meter]])

    if not playerData["StandMeterButton"..type] then
        playerData["StandMeterButton"..type] = Sprite()
        playerData["StandMeterButton"..type]:Load("gfx/stand_user/ui/meter_buttons.anm2", true)
        playerData["StandMeterButton"..type].PlaybackSpeed = 0.25
    end

    ---@type Sprite
    local meter = playerData["StandMeterButton"..type]

    local charge = data.SuperCharge or 0

    if type == 2 or (not forMeter and type == 3) then
        local powerOn = data.PowerOn
        if powerOn then
            meter:SetFrame(ButtonType[type]..Button.charging, Button.frames)
        elseif charge >= STATS.PowerCost then
            if not meter:IsPlaying(ButtonType[type]..Button.charged) and frame % 40 == 0 then
                meter:Play(ButtonType[type]..Button.charged, true)
            end
        else
            meter:SetFrame(ButtonType[type]..Button.charging, math.floor(charge / STATS.PowerCost * Button.frames))
        end
    else
        local powerOn = (data.SuperDuration or 0) > 0
        if powerOn then
            meter:SetFrame(ButtonType[type]..Button.charging, Button.frames)
        elseif charge == STATS.SuperMaxCharge then
            if not meter:IsPlaying(ButtonType[type]..Button.charged) and frame % 40 == 0 then
                meter:Play(ButtonType[type]..Button.charged, true)
            end
        else
            meter:SetFrame(ButtonType[type]..Button.charging, 0)
        end
    end

    local extraOffset = (not forMeter and secondaryOffset) or Vector(0, 0)

    meter:Render(offset + centerOffset + extraOffset, Vector(0, 0), Vector(0, 0))

    if not Game():IsPaused() then
        meter:Update()
    end
    
end

return RenderButton