local utils = {}

function utils:Lerp(first, second, percent)
    return first + (second - first) * percent
end

function utils:VecDir(vec)
    return (math.floor(((vec:GetAngleDegrees() % 360) / 90) + 0.5) % 4)
end

function utils:AdjPos(dir, en)
    return en.Position + (dir * ((en.Size or 0) + 45))
end

return utils
