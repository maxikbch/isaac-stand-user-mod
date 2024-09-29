local character = require("src/constants/character")
local standItem = require("src/stand/item")

---@param player EntityPlayer
local function onPlayerInit(player) 
	local playerData = player:GetData()

	if (player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2) then
		player:EvaluateItems()
		player:AddNullCostume(character.Costume1)
	end

	if (player:GetPlayerType() == character.Type or player:GetPlayerType() == character.Type2)
	and not player:HasCollectible(standItem)
	then
		player:AddCollectible(standItem, 0 , false)
		playerData.StandDisc = standItem
	end
end

return onPlayerInit