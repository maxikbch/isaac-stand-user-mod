
local MeterBar = 
{
	charging = 'charging',
	charged = 'charged',
	uncharging = 'uncharging',
	frames = 30
}

local STATS = require("src/constants/stats")

local RenderButton = require("src/meter/button")

---@param offset Vector
local function RenderMeterBar(frame, playerData, offset, data, type --[[type: {1="super",2="power",3="shift} do not repeat]])

    if not playerData.StandMeter then
        playerData.StandMeter = Sprite()
        playerData.StandMeter:Load("gfx/jotaro/ui/meter_bar.anm2", true)
        playerData.StandMeter.PlaybackSpeed = 0.25
    end

    local meter = playerData.StandMeter

    local charge = data.SuperCharge or 0
    local duration = data.SuperDuration or 0

    if duration > 0 then 
        meter:SetFrame(MeterBar.uncharging, MeterBar.frames - math.floor(duration / STATS.SuperDuration * MeterBar.frames))
    elseif charge == STATS.SuperMaxCharge then
        if type == 2 then
            meter:SetFrame(MeterBar.uncharging, MeterBar.frames)
        elseif not meter:IsPlaying(MeterBar.charged) and frame % 40 == 0 then
            meter:Play(MeterBar.charged, true)
        end
    else
        meter:SetFrame(MeterBar.charging, math.floor(charge / STATS.SuperMaxCharge * MeterBar.frames))
    end

    meter:Render(offset, Vector(0, 0), Vector(0, 0))

    if not Game():IsPaused() then
        meter:Update()
    end

    RenderButton(frame, playerData, offset, data, type, true)
    
end

return RenderMeterBar