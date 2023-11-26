local Compass = {}
Compass.__index = Compass
--[[
	<description>
		This class provides the functionalities for a Compass
	</description> 
	
	<API>
		CompassObj:GetId()
			-- Returns id of tool assigned to instance

		CompassObj:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		CompassObj:Unequip() --> void
			-- Tares down connections such as input, etc
			
		CompassObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Compass.new(tool_obj: Tool, tool_data: { [string]: any }) --> CompassObj
			-- Creates a Compass given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH = "Tools/BaseTool"

local SHIFT_LOCK_EVENT: string = "CameraLock"
local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(0.25, 0.15, 0)

--*************************************************************************************************--

function Compass:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Compass:Equip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, true, SHIFTLOCK_OFFSET)
	self._core_maid._base_tool:Equip()
	self._core_maid._compass_object:Enable(true)
	return
end

function Compass:Unequip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)
	self._core_maid._compass_object:Enable(false)
	self._connection_maid:DoCleaning()
	self._core_maid._base_tool:Unequip()
	return
end

function Compass:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()
	self.Core.Fire(SHIFT_LOCK_EVENT, false)
	self._tool_data = nil
	self._connection_maid = nil
	self._tool = nil
	self._core_maid = nil
	self = nil

	return
end

function Compass.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Compass)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)
	self._core_maid._compass_object = self.Core.UIManager.GetCompass()

	return self
end

return Compass
