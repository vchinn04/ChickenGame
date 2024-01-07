local ChickenHat = {
	Name = "ChickenHat",
}
ChickenHat.__index = ChickenHat
--[[
	<description>
		This class is responsible for handling the standard ChickenHat functionality.
	</description> 
	
	<API>
		ChickenHatObj:GetToolObject() ---> Instance
			-- return the tool object 

		ChickenHatObj:GetId() ---> string?
			-- return the tool id 

		ChickenHatObj:Destroy() ---> nil
			-- Cleanup connections and objects of ChickenHatObj

		ChickenHat.new(player, player_object, tool_data) ---> ChickenHatObj
			-- Create a new ChickenHatObj
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

function ChickenHat:EventHandler(): nil
	return
end

function ChickenHat:GetToolObject(): Instance
	return self._maid.BaseAccessory:GetTool()
end

function ChickenHat:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function ChickenHat:Destroy(): nil
	self._maid:DoCleaning()

	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function ChickenHat.new(player, player_object, tool_data)
	local self = setmetatable({}, ChickenHat)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseAccessory = self.Core.Components[BASE_ACCESSORY_PATH].new(player, tool_data)

	return self
end

return ChickenHat
