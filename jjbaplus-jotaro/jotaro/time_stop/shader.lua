local context = require("jotaro.time_stop.context")

local Audio = _G.JoJoStandFramework.Audio

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

    context.forEachStarPlatinumPlayer(JSF, function(player, standDef)
        local duration = context.getSkillDuration(player, JSF)
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
                Audio.play(standDef.sounds.tick9)
            elseif duration == 157 then
                Audio.play(standDef.sounds.tick5)
            elseif duration == 1 then
                Audio.play(standDef.sounds.resumeTime)
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
