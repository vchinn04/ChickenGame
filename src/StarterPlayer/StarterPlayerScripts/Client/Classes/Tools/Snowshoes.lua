local Snowshoes = {}
Snowshoes.__index = Snowshoes
--[[
	<description>
		This class provides the functionalities for a Snowshoes
	</description> 
	
	<API>
		SnowshoesObj:GetId()
			-- Returns id of tool assigned to instance

		SnowshoesObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Snowshoes.new(tool_obj: Tool, tool_data: { [string]: any }) --> SnowshoesObj
			-- Creates a Snowshoes given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local SPEED_CHANGE_EVENT: string = "SpeedAction"
local SPEED_MULTIPLIER: number = 1.5
--*************************************************************************************************--

function Snowshoes:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Snowshoes:Destroy(): nil
	self._maid:DoCleaning()
	self.Core.Fire(SPEED_CHANGE_EVENT, "Snowshoes", nil)
	self._tool_data = nil
	self._tool = nil
	self._maid = nil
	self = nil
	return
end

function Snowshoes.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Snowshoes)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._maid = self.Core.Utils.Maid.new()

	self._maid.SnowEvent = self.Core.Subscribe("Snow", function(status: boolean)
		if status then
			self.Core.Fire(SPEED_CHANGE_EVENT, "Snowshoes", SPEED_MULTIPLIER)
		else
			self.Core.Fire(SPEED_CHANGE_EVENT, "Snowshoes", nil)
		end
	end)

	if self.Core.PlayerMovement.IsOnSnow() then
		self.Core.Fire(SPEED_CHANGE_EVENT, "Snowshoes", SPEED_MULTIPLIER)
	end

	return self
end

return Snowshoes
