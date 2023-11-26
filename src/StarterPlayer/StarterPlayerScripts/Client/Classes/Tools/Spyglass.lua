local Spyglass = {}
Spyglass.__index = Spyglass
--[[
	<description>
		This class provides the functionalities for a Spyglass
	</description> 
	
	<API>
		SpyglassObj:GetId()
			-- Returns id of tool assigned to instance

		SpyglassObj:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		SpyglassObj:Unequip() --> void
			-- Tares down connections such as input, etc
			
		SpyglassObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Spyglass.new(tool_obj: Tool, tool_data: { [string]: any }) --> SpyglassObj
			-- Creates a Spyglass given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
local FIRST_PERSON_EVENT: string = "FirstPerson"

local ZOOM_EVENT: string = "ZoomFOV"
local ZOOM_DELTA: number = 15
local ZOOM_DELTA_DURATION: number = 0.5
local MAX_ZOOM_FOV: number = 25 -- The lower the FOV the further can zoom in
local MIN_ZOOM_FOV: number = 70 -- Ideally don't change since cant zoom out further than default FOV.

local FOV_LIMITS: { number } = { MIN_ZOOM_FOV, MAX_ZOOM_FOV }

local ContextActionService = game:GetService("ContextActionService")

--*************************************************************************************************--

function Spyglass:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Spyglass:UserInput(): nil
	self._connection_maid:GiveBindAction("ZoomIn")
	ContextActionService:BindAction(
		"ZoomIn",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Cancel then
				return Enum.ContextActionResult.Pass
			end

			if input_state == Enum.UserInputState.Begin then
				self.Core.Fire(ZOOM_EVENT, true, -ZOOM_DELTA, ZOOM_DELTA_DURATION, FOV_LIMITS)
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.Q
	)

	self._connection_maid:GiveBindAction("ZoomOut")
	ContextActionService:BindAction(
		"ZoomOut",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Cancel then
				return Enum.ContextActionResult.Pass
			end

			if input_state == Enum.UserInputState.Begin then
				self.Core.Fire(ZOOM_EVENT, true, ZOOM_DELTA, ZOOM_DELTA_DURATION, FOV_LIMITS)
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.E
	)
	return
end

function Spyglass:Equip(): nil
	self._core_maid._base_tool:Equip()
	self.Core.Fire(FIRST_PERSON_EVENT, true)
	self:UserInput()
	return
end

function Spyglass:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._core_maid._base_tool:Unequip()
	self.Core.Fire(FIRST_PERSON_EVENT, false)
	self.Core.Fire(ZOOM_EVENT, false)
	return
end

function Spyglass:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self.Core.Fire(FIRST_PERSON_EVENT, false)
	self.Core.Fire(ZOOM_EVENT, false)

	self._tool_data = nil
	self._connection_maid = nil
	self._tool = nil
	self._core_maid = nil
	self = nil

	return
end

function Spyglass.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Spyglass)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)

	self.Core.Utils.UtilityFunctions.MakeTransparent(tool_obj)

	return self
end

return Spyglass
