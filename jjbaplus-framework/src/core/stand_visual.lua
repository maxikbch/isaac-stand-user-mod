local function updateStandVisual(player, standDef, standEntity, standData)
    local standSprite = standEntity:GetSprite()
    local floatbounce = 3 * Vector.FromAngle(standEntity.FrameCount * 9).Y
    standEntity.PositionOffset = standDef.floatOffset + Vector(0, floatbounce)

    if standData.alpha < standData.alphagoal then
        standData.alpha = math.min(standData.alphagoal, standData.alpha + .35)
    elseif standData.alpha > standData.alphagoal then
        standData.alpha = math.max(standData.alphagoal, standData.alpha - .35)
    end

    if standData.alpha <= 0 then
        standSprite.Scale = Vector(0, 0)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
        standSprite.Scale = Vector(1.2, 1.2)
    else
        standSprite.Scale = Vector(1, 1)
    end

    standSprite.Color = Color(1, 1, 1, math.max(0, standData.alpha), 0, 0, 0)
end

local function updateBehaviorState(standData)
    if standData.behavior ~= standData.behaviorlast then
        standData.behaviorlast = standData.behavior
        standData.statetime = 0
    else
        standData.statetime = standData.statetime + 1
    end
end

return {
    updateStandVisual = updateStandVisual,
    updateBehaviorState = updateBehaviorState,
}
