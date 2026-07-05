local Settings = require("src/constants/settings")

local input = {}

function input:IsKeyboardController(controllerIndex)
	return controllerIndex == 0 and Input.IsKeyboardEnabled()
end

function input:IsSkill1Triggered(controllerIndex)
	if self:IsKeyboardController(controllerIndex) then
		return Input.IsButtonTriggered(Settings.KEY_SKILL1, 0)
	end
	return Input.IsButtonTriggered(Settings.BUTTON_SKILL1, controllerIndex)
end

function input:IsSkill2Triggered(controllerIndex)
	if self:IsKeyboardController(controllerIndex) then
		return Input.IsButtonTriggered(Settings.KEY_SKILL2, 0)
	end
	return Input.IsButtonTriggered(Settings.BUTTON_SKILL2, controllerIndex)
end

return input
