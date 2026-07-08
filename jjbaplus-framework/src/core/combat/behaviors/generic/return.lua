return function(player, standDef, jsf, shootDir)
    local standEntity = jsf.standEntity
    local standData = standEntity:GetData()

    if standData.behavior ~= "return" then
        return
    end

    if standData.alpha <= 0 then
        standData.behavior = "idle"
        standData.posrate = 1
        standEntity.Position = player.Position
        standEntity.Velocity = Vector(0, 0)
        standData.alpha = -3
    else
        standData.alphagoal = -3
        standEntity.Velocity = standEntity.Velocity * .8
    end
end
