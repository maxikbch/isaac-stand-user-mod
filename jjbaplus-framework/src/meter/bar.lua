local MeterBar =
{
    charging = 'charging',
    charged = 'charged',
    uncharging = 'uncharging',
    frames = 30
}

local RenderButton = require("src/meter/button")

local DEFAULT_BAR = "gfx/stand_framework/ui/meter_bar.anm2"

return function(frame, playerData, offset, data, stats, type, meterGfx)
    local barPath = (meterGfx and meterGfx.bar) or DEFAULT_BAR

    if not playerData.StandMeter or playerData.StandMeterBarPath ~= barPath then
        playerData.StandMeter = Sprite()
        playerData.StandMeter:Load(barPath, true)
        playerData.StandMeter.PlaybackSpeed = 0.25
        playerData.StandMeterBarPath = barPath
    end

    local meter = playerData.StandMeter
    local charge = data.SuperCharge or 0
    local duration = data.SuperDuration or 0

    if duration > 0 then
        meter:SetFrame(MeterBar.uncharging, MeterBar.frames - math.floor(duration / stats.SuperDuration * MeterBar.frames))
    elseif charge == stats.SuperMaxCharge then
        if type == 2 then
            meter:SetFrame(MeterBar.uncharging, MeterBar.frames)
        elseif not meter:IsPlaying(MeterBar.charged) and frame % 40 == 0 then
            meter:Play(MeterBar.charged, true)
        end
    else
        meter:SetFrame(MeterBar.charging, math.floor(charge / stats.SuperMaxCharge * MeterBar.frames))
    end

    meter:Render(offset, Vector(0, 0), Vector(0, 0))

    if not Game():IsPaused() then
        meter:Update()
    end

    RenderButton(frame, playerData, offset, data, stats, type, true, meterGfx)
end
