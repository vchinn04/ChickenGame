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

local ContextActionService = game:GetService("ContextActionService")

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

function Basket:Equip(): nil
	self._core_maid._base_tool:Equip()

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, true)
	end

	self:UserInput()
	return
end

function Basket:Unequip(): nil
	if self._connection_maid then
		self._connection_maid:DoCleaning()
	end
	if self._core_maid and self._core_maid._base_tool then
		self._core_maid._base_tool:Unequip()
	end
	if self._tool_data then
		for _, event in self._tool_data.EquipEvents do
			self.Core.Fire(event, false)
		end
	end
	return
end

function Basket:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, false)
	end

	self._tool_data = nil
	self._connection_maid = nil
	self._tool = nil
	self._core_maid = nil
	self = nil

	return
end

function Basket.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Basket)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)

	return self
end

return Basket
