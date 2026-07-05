local MeterBar =
{
    charging = 'charging',
    charged = 'charged',
    uncharging = 'uncharging',
    frames = 30
}

local RenderButton = require("src/meter/button")

return function(frame, playerData, offset, data, stats, type)
    if not playerData.StandMeter then
        playerData.StandMeter = Sprite()
        playerData.StandMeter:Load("gfx/stand_framework/ui/meter_bar.anm2", true)
        playerData.StandMeter.PlaybackSpeed = 0.25
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

    RenderButton(frame, playerData, offset, data, stats, type, true)
end
