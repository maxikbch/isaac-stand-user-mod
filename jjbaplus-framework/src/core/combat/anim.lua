local anim = {}

function anim.dirSuffix(launchdir)
    if not launchdir then
        return "W"
    end
    if launchdir.Y == -1 then
        return "N"
    elseif launchdir.X == 1 then
        return "E"
    elseif launchdir.Y == 1 then
        return "S"
    elseif launchdir.X == -1 then
        return "W"
    end
    return "W"
end

function anim.playDir(sprite, prefix, launchdir)
    sprite:Play(prefix .. anim.dirSuffix(launchdir))
end

function anim.isFinishedDir(sprite, prefix)
    return sprite:IsFinished(prefix .. "N")
        or sprite:IsFinished(prefix .. "E")
        or sprite:IsFinished(prefix .. "S")
        or sprite:IsFinished(prefix .. "W")
end

function anim.cardinalAngle(launchdir)
    local suffix = anim.dirSuffix(launchdir)
    if suffix == "N" then
        return 270
    elseif suffix == "E" then
        return 0
    elseif suffix == "S" then
        return 90
    end
    return 180
end

function anim.cardinalOffset(launchdir, distance)
    distance = distance or 20
    local suffix = anim.dirSuffix(launchdir)
    if suffix == "N" then
        return Vector(0, -distance)
    elseif suffix == "E" then
        return Vector(distance, 0)
    elseif suffix == "S" then
        return Vector(0, distance)
    end
    return Vector(-distance, 0)
end

return anim
