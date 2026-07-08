local function ensureInput(jsf)
    if not jsf.input then
        jsf.input = {
            shoot = false,
            shootpress = false,
            shootrelease = false,
            releasedir = Vector(0, 0),
        }
    end
    return jsf.input
end

local function updateInput(player, jsf, shootDir)
    local input = ensureInput(jsf)

    input.shootpress = false
    input.shootrelease = false

    if shootDir:Length() ~= 0 or Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) or player:AreOpposingShootDirectionsPressed() then
        if input.shoot == false then
            input.shootpress = true
        end
        input.shoot = true
        input.releasedir = shootDir
    else
        if input.shoot == true then
            input.shootrelease = true
        end
        input.shoot = false
    end

    return input
end

return {
    ensureInput = ensureInput,
    updateInput = updateInput,
}
