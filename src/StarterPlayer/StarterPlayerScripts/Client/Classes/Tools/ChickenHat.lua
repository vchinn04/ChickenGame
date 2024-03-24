local ChickenHat = {}
ChickenHat.__index = ChickenHat
--[[
	<description>
		This class provides the functionalities for a ChickenHat
	</description> 
	
	<API>
		ChickenHatObj:GetId()
			-- Returns id of tool assigned to instance

		ChickenHatObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		ChickenHat.new(tool_obj: Tool, tool_data: { [string]: any }) --> ChickenHatObj
			-- Creates a ChickenHat given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.Parent.ClientTypes)
--*************************************************************************************************--

function ChickenHat:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function ChickenHat:Destroy(): nil
	self.Core.Fire("EnableDoubleJump", "ChickenHat", false)
	print("DESTROY CHICKEN HAT")
	self._tool_data = nil
	self._tool = nil
	self = nil
	return
end

function ChickenHat.new(tool_obj: Tool, tool_data: types.ToolData): types.ChickenHatObject
	local self: types.ChickenHatObject = setmetatable({} :: types.ChickenHatObject, ChickenHat)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self.Core.Fire("EnableDoubleJump", "ChickenHat", true)
	print("CREATE CHICKEN HAT")

	return self
end

return ChickenHat
