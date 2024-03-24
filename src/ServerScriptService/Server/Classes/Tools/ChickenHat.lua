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

local types = require(script.Parent.Parent.Parent.ServerTypes)
local BASE_ACCESSORY: types.BaseAccessory = require(script.Parent.Components.BaseAccessory)
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

function ChickenHat.new(player, player_object, tool_data): types.ChickenHatObject
	local self: types.ChickenHatObject = setmetatable({} :: types.ChickenHatObject, ChickenHat)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._player = player :: Player
	self._tool_data = tool_data :: types.ToolData
	self._player_object = player_object :: types.PlayerObject

	self._maid.BaseAccessory = BASE_ACCESSORY.new(player, tool_data) :: types.BaseAccessoryObject

	return self
end

return ChickenHat
