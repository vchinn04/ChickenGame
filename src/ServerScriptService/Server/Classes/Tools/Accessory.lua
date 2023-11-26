local Accessory = {
	Name = "Accessory",
}
Accessory.__index = Accessory
--[[
	<description>
		This class is responsible for handling the standard Accessory functionality.
	</description> 
	
	<API>
		AccessoryObj:GetToolObject() ---> Instance
			-- return the tool object 

		AccessoryObj:GetId() ---> string?
			-- return the tool id 

		AccessoryObj:Destroy() ---> nil
			-- Cleanup connections and objects of AccessoryObj

		Accessory.new(player, player_object, tool_data) ---> AccessoryObj
			-- Create a new AccessoryObj
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

function Accessory:EventHandler(): nil
	return
end

function Accessory:GetToolObject(): Instance
	return self._maid.BaseAccessory:GetTool()
end

function Accessory:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Accessory:Destroy(): nil
	self._maid:DoCleaning()

	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function Accessory.new(player, player_object, tool_data)
	local self = setmetatable({}, Accessory)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseAccessory = self.Core.Components[BASE_ACCESSORY_PATH].new(player, tool_data)

	return self
end

return Accessory
