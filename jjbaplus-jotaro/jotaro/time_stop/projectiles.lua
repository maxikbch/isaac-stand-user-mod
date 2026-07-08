local context = require("jotaro.time_stop.context")

local function onProjectileUpdate(tear, JSF)
    local source = tear.SpawnerEntity
    if not source then
        return
    end

    local player = source:ToPlayer()
    if not player then
        return
    end

    local _, standState = context.getStandContext(player, JSF)
    if not standState then
        return
    end

    local duration = context.getSkillDuration(standState)
    if duration == 1 then
        local data = tear:GetData()
        data.TimeFrozen = false
        tear.Velocity = data.StoredVel
        tear.FallingSpeed = data.StoredFall
        tear.FallingAccel = data.StoredAcc
    elseif duration > 1 then
        local data = tear:GetData()
        if not data.TimeFrozen then
            data.TimeFrozen = true
            data.StoredVel = tear.Velocity
            data.StoredFall = tear.FallingSpeed
            data.StoredAcc = tear.FallingAccel
        else
            tear.Velocity = Vector(0, 0)
            tear.FallingAccel = -0.1
            tear.FallingSpeed = 0
        end
    end
end

return {
    onProjectileUpdate = onProjectileUpdate,
}
