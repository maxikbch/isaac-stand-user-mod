

return function (player, stand, shootDir)
    
	local playerData = player:GetData()
	local standData = playerData[stand.Id]:GetData()

    if standData.behavior == 'return' then
        if standData.alpha <= 0 then
            standData.behavior = 'idle'
            standData.posrate = 1
            standData.Position = player.Position
            standData.Velocity = Vector(0, 0)
            standData.alpha = -3
        else
            standData.alphagoal = -3
            playerData[stand.Id].Velocity = playerData[stand.Id].Velocity * .8
        end
    end
end