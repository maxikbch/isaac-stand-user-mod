local Settings = require("src/constants/settings")

local input = {}

function input:IsKeyboardController(controllerIndex)
	return controllerIndex == 0
end

function input:IsSuperTriggered(controllerIndex)
	if self:IsKeyboardController(controllerIndex) then
		return Input.IsButtonTriggered(Settings.KEY_SUPER, 0)
	end
	return Input.IsButtonTriggered(Settings.BUTTON_SUPER, controllerIndex)
end

function input:IsAltTriggered(controllerIndex)
	if self:IsKeyboardController(controllerIndex) then
		return Input.IsButtonTriggered(Settings.KEY_ALT, 0)
	end
	return Input.IsButtonTriggered(Settings.BUTTON_ALT, controllerIndex)
end

return input
