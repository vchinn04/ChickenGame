local Bandage = {}
Bandage.__index = Bandage
--[[
	<description>
		This class provides the functionalities for a Bandage
	</description> 
	
	<API>
		BandageObj:GetId()
			-- Returns id of tool assigned to instance

		BandageObj:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		BandageObj:Unequip() --> void
			-- Tares down connections such as input, etc
			
		BandageObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Bandage.new(tool_obj: Tool, tool_data: { [string]: any }) --> BandageObj
			-- Creates a Bandage given the tool data and tool instance. 
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

function Bandage:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Bandage:UserInput(): nil
	self._connection_maid:GiveBindAction("Heal")
	ContextActionService:BindAction("Heal", function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if input_state == Enum.UserInputState.Begin then
			self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(TOGGLE_REMOTE_EVENT)
		end

		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton1)

	return
end

function Bandage:Equip(): nil
	self._core_maid._base_tool:Equip()

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, true)
	end

	self:UserInput()
	return
end

function Bandage:Unequip(): nil
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

function Bandage:Destroy(): nil
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

function Bandage.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Bandage)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)

	return self
end

return Bandage
