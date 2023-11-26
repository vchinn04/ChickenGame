local Torch = {}
Torch.__index = Torch
--[[
	<description>
		This class provides the functionalities for a Torch
	</description> 
	
	<API>
		TorchObj:GetId()
			-- Returns id of tool assigned to instance

		TorchObj:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		TorchObj:Unequip() --> void
			-- Tares down connections such as input, etc
			
		TorchObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Torch.new(tool_obj: Tool, tool_data: { [string]: any }) --> TorchObj
			-- Creates a Torch given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
local TOGGLE_REMOTE_EVENT: string = "Toggle"
local CHARGE_CLASS_PATH: string = "Misc/ChargeClass"

local ContextActionService = game:GetService("ContextActionService")

local TRIGGER_DURATION: number = 0.25

--*************************************************************************************************--

function Torch:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Torch:UserInput(): nil
	self._connection_maid:GiveBindAction("Light")
	ContextActionService:BindAction("Light", function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if input_state == Enum.UserInputState.Begin then -- IMPROVEMENT: Change to promise.delay
			self._core_maid._charge_object:Charge(100, TRIGGER_DURATION, function(new_charge: number)
				self._core_maid._cursor_bar:Set(new_charge / 100)
			end, function(_)
				self:CancelCharge()
				self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Toggle)
			end)
		else
			self:CancelCharge()
		end

		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton1)

	return
end

function Torch:CancelCharge(): nil
	self._core_maid._charge_object:CancelCharge()
	self._core_maid._cursor_bar:Reset()
	return
end

function Torch:Equip(): nil
	self._core_maid._base_tool:Equip()
	self._core_maid._cursor_bar:Show()
	if self._tool_data.AnimationHitmark then
		self._connection_maid:GiveTask(
			self._core_maid.Animator:GetMarkerReachedSignal(
				self._tool_data.AnimationData.Toggle,
				self._tool_data.AnimationHitmark,
				function()
					self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(TOGGLE_REMOTE_EVENT)
				end
			)
		)
	end

	self:UserInput()
	return
end

function Torch:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._core_maid._base_tool:Unequip()
	self:CancelCharge()
	self._core_maid._cursor_bar:Hide()

	return
end

function Torch:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()
	self:CancelCharge()
	self._tool_data = nil
	self._connection_maid = nil
	self._tool = nil
	self._core_maid = nil
	self = nil

	return
end

function Torch.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Torch)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid._cursor_bar = self.Core.UIManager.GetCursorBar()
	self._core_maid._charge_object = self.Core.Components[CHARGE_CLASS_PATH].new()

	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)

	return self
end

return Torch
