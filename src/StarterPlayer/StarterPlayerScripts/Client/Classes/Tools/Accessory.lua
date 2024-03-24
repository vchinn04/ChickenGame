local Accessory = {}
Accessory.__index = Accessory
--[[
	<description>
		This class provides the functionalities for a Accessory
	</description> 
	
	<API>
		AccessoryObj:GetId()
			-- Returns id of tool assigned to instance

		AccessoryObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Accessory.new(tool_obj: Tool, tool_data: { [string]: any }) --> AccessoryObj
			-- Creates a Accessory given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.Parent.ClientTypes)
--*************************************************************************************************--

function Accessory:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Accessory:Destroy(): nil
	self._tool_data = nil
	self._tool = nil
	self = nil
	return
end

function Accessory.new(tool_obj: Tool, tool_data: types.ToolData): types.AccessoryObject
	local self: types.AccessoryObject = setmetatable({} :: types.AccessoryObject, Accessory)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	return self
end

return Accessory
