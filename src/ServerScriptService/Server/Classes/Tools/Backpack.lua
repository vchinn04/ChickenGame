local Backpack = {
	Name = "Backpack",
}
Backpack.__index = Backpack
--[[
	<description>
		This class is responsible for handling the standard Backpack accessory functionality.
	</description> 
	
	<API>
		BackpackObj:GetToolObject() ---> Instance
			-- return the tool object 

		BackpackObj:GetId() ---> string?
			-- return the tool id 

		BackpackObj:Destroy() ---> nil
			-- Cleanup connections and objects of BackpackObj

		Backpack.new(player, player_object, tool_data) ---> BackpackObj
			-- Create a new BackpackObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_ACCESSORY_PATH: string = "Tools/BaseAccessory"
--*************************************************************************************************--

function Backpack:EventHandler(): nil
	return
end

function Backpack:GetToolObject(): Instance
	return self._maid.BaseAccessory:GetTool()
end

function Backpack:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Backpack:Destroy(): nil
	self._maid:DoCleaning()

	self.Core.DataManager.RemoveSpaceAddtion(self._player, self._tool_data.SpaceAddition)

	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil
	return
end

function Backpack.new(player, player_object, tool_data)
	local self = setmetatable({}, Backpack)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseAccessory = self.Core.Components[BASE_ACCESSORY_PATH].new(player, tool_data)

	self.Core.DataManager.AddSpaceAddtion(player, tool_data.SpaceAddition)

	return self
end

return Backpack
