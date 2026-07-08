local context = require("jotaro.time_stop.context")

local sfx = SFXManager()
local music = MusicManager()

local function onShader(name, JSF)
    if name ~= "ZaWarudo" then
        return nil
    end

    local dist = 0
    local on = 0
    local standDef = JSF:GetStand(context.STAND_ID)
    if not standDef then
        return { DistortionScale = 0, DistortionOn = 0 }
    end

    local maxTime = standDef.stats.SuperDuration

    context.forEachStarPlatinumPlayer(JSF, function(_, _, standState)
        local duration = context.getSkillDuration(standState)
        if duration > 0 then
            dist = 1 / (maxTime - 2 - duration)
                + 1 / (duration - 2)
            if dist < 0 then
                dist = math.abs(dist) ^ 2
            elseif duration - 2 == 0 or maxTime - 2 - duration == 0 then
                dist = 1
            else
                on = 0.5
            end
            if duration == 277 then
                sfx:Play(standDef.sounds.tick9, 5, 0, false, 1)
            elseif duration == 157 then
                sfx:Play(standDef.sounds.tick5, 5, 0, false, 1)
            elseif duration == 1 then
                sfx:Play(standDef.sounds.resumeTime, 2, 0, false, 1)
                music:Resume()
            end
        end
    end)

    if shaderAPI then
        shaderAPI.Shader("ZaWarudo", { DistortionScale = dist, DistortionOn = on })
    else
        return { DistortionScale = dist, DistortionOn = on }
    end
end

return {
    onShader = onShader,
}
