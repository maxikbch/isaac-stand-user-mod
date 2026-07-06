local Settings = require("src/constants/settings")

-- IsButtonTriggered can be consumed by the game or other mods before POST_UPDATE runs.
-- Edge detection via IsButtonPressed is reliable and is polled once per button per frame.
local input = {
	prevPressed = {},
	frameCache = {},
	lastFrame = -1,
}

local function cacheKey(controllerIndex, button)
	return controllerIndex .. ":" .. button
end

function input:OnPostUpdate()
	local frame = Game():GetFrameCount()
	if frame ~= self.lastFrame then
		self.frameCache = {}
		self.lastFrame = frame
	end
end

function input:WasButtonPressedEdge(controllerIndex, button)
	local ck = cacheKey(controllerIndex, button)
	local cached = self.frameCache[ck]
	if cached ~= nil then
		return cached
	end

	local pressed = Input.IsButtonPressed(button, controllerIndex)
	local wasPressed = self.prevPressed[ck] or false
	local triggered = pressed and not wasPressed

	self.prevPressed[ck] = pressed
	self.frameCache[ck] = triggered
	return triggered
end

function input:IsSkill1Triggered(controllerIndex)
	return self:WasButtonPressedEdge(controllerIndex, Settings.KEY_SKILL1)
		or self:WasButtonPressedEdge(controllerIndex, Settings.BUTTON_SKILL1)
end

function input:IsSkill2Triggered(controllerIndex)
	return self:WasButtonPressedEdge(controllerIndex, Settings.KEY_SKILL2)
		or self:WasButtonPressedEdge(controllerIndex, Settings.BUTTON_SKILL2)
end

return input
