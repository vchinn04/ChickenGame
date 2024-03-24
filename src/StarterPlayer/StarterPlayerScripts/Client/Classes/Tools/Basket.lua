local Basket = {}
Basket.__index = Basket
--[[
	<description>
		This class provides the functionalities for a Basket
	</description> 
	
	<API>
		BasketObj:GetId()
			-- Returns id of tool assigned to instance

		BasketObj:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		BasketObj:Unequip() --> void
			-- Tares down connections such as input, etc
			
		BasketObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Basket.new(tool_obj: Tool, tool_data: { [string]: any }) --> BasketObj
			-- Creates a Basket given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
local TOGGLE_REMOTE_EVENT: string = "Trigger"
local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(2.25, 0.25, 0)
local SHIFT_LOCK_EVENT: string = "CameraLock"
local ContextActionService = game:GetService("ContextActionService")

local types = require(script.Parent.Parent.Parent.ClientTypes)
--*************************************************************************************************--

function Basket:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Basket:UserInput(): nil
	return
end

function Basket:Destroy(): nil
	self._maid:DoCleaning()

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, false)
	end

	self._tool_data = nil
	self._tool = nil
	self._maid = nil
	self = nil

	return
end

function Basket.new(tool_obj: Tool, tool_data: types.ToolData): types.BasketObject
	local self: types.BasketObject = setmetatable({} :: types.BasketObject, Basket)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._maid = self.Core.Utils.Maid.new()

	self._maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, true)
	end

	return self
end

return Basket
