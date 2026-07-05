local Button =
{
    charging = 'charging',
    charged = 'charged',
    frames = 22
}

local ButtonType = {"super - ", "power - ", "shift - "}

local centerOffset = Vector(8.5, 34)
local secondaryOffset = Vector(0, 15)

local DEFAULT_BUTTONS = "gfx/stand_framework/ui/meter_buttons.anm2"

return function(frame, playerData, offset, data, stats, type, forMeter, meterGfx)
    local buttonsPath = (meterGfx and meterGfx.buttons) or DEFAULT_BUTTONS
    local buttonKey = "StandMeterButton" .. type

    if not playerData[buttonKey] or playerData[buttonKey .. "Path"] ~= buttonsPath then
        playerData[buttonKey] = Sprite()
        playerData[buttonKey]:Load(buttonsPath, true)
        playerData[buttonKey].PlaybackSpeed = 0.25
        playerData[buttonKey .. "Path"] = buttonsPath
    end

    local meter = playerData[buttonKey]
    local charge = data.SuperCharge or 0

    if type == 2 or (not forMeter and type == 3) then
        local powerOn = data.PowerOn
        if powerOn then
            meter:SetFrame(ButtonType[type]..Button.charging, Button.frames)
        elseif charge >= stats.PowerCost then
            if not meter:IsPlaying(ButtonType[type]..Button.charged) and frame % 40 == 0 then
                meter:Play(ButtonType[type]..Button.charged, true)
            end
        else
            meter:SetFrame(ButtonType[type]..Button.charging, math.floor(charge / stats.PowerCost * Button.frames))
        end
    else
        local powerOn = (data.SuperDuration or 0) > 0
        if powerOn then
            meter:SetFrame(ButtonType[type]..Button.charging, Button.frames)
        elseif charge == stats.SuperMaxCharge then
            if not meter:IsPlaying(ButtonType[type]..Button.charged) and frame % 40 == 0 then
                meter:Play(ButtonType[type]..Button.charged, true)
            end
        else
            meter:SetFrame(ButtonType[type]..Button.charging, math.floor(charge / stats.SuperMaxCharge * Button.frames))
        end
    end

    local extraOffset = (not forMeter and secondaryOffset) or Vector(0, 0)

    meter:Render(offset + centerOffset + extraOffset, Vector(0, 0), Vector(0, 0))

    if not Game():IsPaused() then
        meter:Update()
    end
end
