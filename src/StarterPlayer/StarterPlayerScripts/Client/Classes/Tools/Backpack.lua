local Backpack = {}
Backpack.__index = Backpack
--[[
	<description>
		This class provides the functionalities for a Backpack
	</description> 
	
	<API>
		BackpackObj:GetId()
			-- Returns id of tool assigned to instance

		BackpackObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Backpack.new(tool_obj: Tool, tool_data: { [string]: any }) --> BackpackObj
			-- Creates a Backpack given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function Backpack:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Backpack:Destroy(): nil
	self._tool_data = nil
	self._tool = nil
	self = nil
	return
end

function Backpack.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Backpack)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	return self
end

return Backpack
