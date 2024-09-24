
local utils = {}

function utils:Lerp(first,second,percent)
	return (first + (second - first)*percent)
end

function utils:log(log, ...)
	local args = {...}
	for _, v in ipairs(args) do
		table.insert(log, tostring(v))
	end
end

function utils:hasbit(x, p)
	return (x & p) == p
end

function utils:VecDir(vec)
	return(math.floor(((vec:GetAngleDegrees() % 360) / 90) + .5) % 4)
end

---@param player EntityPlayer
function utils:GetShootDir(player)
	
	local shootDir = player:GetShootingInput()

	if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) then
		if shootDir.X == 0 and shootDir.Y == 0 then
			shootDir = Vector(-1, 0):Rotated(player:GetHeadDirection() * 90)
		end
	end

	local xx = shootDir.X
	local yy = shootDir.Y
	if yy > .5 then
		yy = 1
		xx = 0
	elseif yy < -.5 then
		yy = -1
		xx = 0
	else
		yy = 0
		if xx > .5 then
			xx = 1
		elseif xx < -.5 then
			xx = -1
		else
			xx = 0
		end
	end
	shootDir = Vector(xx, yy)

	return shootDir
end

function utils:AdjPos(dir, en)
	return en.Position + Vector(0, 0) + (dir * (en.Size + 45))
end

return utils