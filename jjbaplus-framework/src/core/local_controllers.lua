-- Tracks controller indices that receive input on this machine (vanilla API).
-- Used to show stand meters only for locally controlled players in multiplayer.

local LocalControllers = {
    active = {},
}

local INPUT_ACTIONS = {
    ButtonAction.ACTION_LEFT,
    ButtonAction.ACTION_RIGHT,
    ButtonAction.ACTION_UP,
    ButtonAction.ACTION_DOWN,
    ButtonAction.ACTION_SHOOTLEFT,
    ButtonAction.ACTION_SHOOTRIGHT,
    ButtonAction.ACTION_SHOOTUP,
    ButtonAction.ACTION_SHOOTDOWN,
    ButtonAction.ACTION_BOMB,
    ButtonAction.ACTION_ITEM,
    ButtonAction.ACTION_PILLCARD,
    ButtonAction.ACTION_DROP,
}

function LocalControllers:Reset()
    self.active = {}
end

function LocalControllers:MarkActive(controllerIndex)
    self.active[controllerIndex] = true
end

function LocalControllers:IsActive(controllerIndex)
    return self.active[controllerIndex] == true
end

function LocalControllers:GetActiveCount()
    local count = 0
    for _ in pairs(self.active) do
        count = count + 1
    end
    return count
end

function LocalControllers:IsReceivingInput(controllerIndex)
    for _, action in ipairs(INPUT_ACTIONS) do
        if Input.IsActionTriggered(action, controllerIndex) or Input.IsActionPressed(action, controllerIndex) then
            return true
        end
    end

    if controllerIndex == 0 then
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) or Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_2) then
            return true
        end
    end

    return false
end

function LocalControllers:Update()
    if Game():GetNumPlayers() <= 1 then
        self:MarkActive(0)
        local player = Isaac.GetPlayer(0)
        if player and player:Exists() then
            self:MarkActive(player.ControllerIndex)
        end
        return
    end

    for controllerIndex = 0, 4 do
        if self:IsReceivingInput(controllerIndex) then
            self:MarkActive(controllerIndex)
        end
    end
end

return LocalControllers
