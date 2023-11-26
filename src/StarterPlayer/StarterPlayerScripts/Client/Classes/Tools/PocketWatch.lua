local PocketWatch = {}
PocketWatch.__index = PocketWatch
--[[
	<description>
		This class provides the functionalities for a PocketWatch
	</description> 
	
	<API>
		PocketWatchObj:GetId()
			-- Returns id of tool assigned to instance
			
		PocketWatchObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		PocketWatch.new(tool_obj: Tool, tool_data: { [string]: any }) --> PocketWatchObj
			-- Creates a PocketWatch given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function PocketWatch:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function PocketWatch:Destroy(): nil
	self._maid:DoCleaning()
	self._tool_data = nil
	self._maid = nil
	self._tool = nil
	self = nil
	return
end

function PocketWatch.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, PocketWatch)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._maid = self.Core.Utils.Maid.new()

	self._maid._pocketwatch_object = self.Core.UIManager.GetPocketWatch()

	return self
end

return PocketWatch
