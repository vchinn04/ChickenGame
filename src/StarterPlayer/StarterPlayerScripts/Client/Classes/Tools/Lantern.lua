local Lantern = {}
Lantern.__index = Lantern
--[[
	<description>
		This class provides the functionalities for a Lantern
	</description> 
	
	<API>
		LanternObj:GetId()
			-- Returns id of tool assigned to instance
			
		LanternObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Lantern.new(tool_obj: Tool, tool_data: { [string]: any }) --> LanternObj
			-- Creates a Lantern given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local CHARGE_DURATION: number = 0.25
local TOGGLE_REMOTE_EVENT: string = "Toggle"

local ContextActionService = game:GetService("ContextActionService")

--*************************************************************************************************--

function Lantern:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Lantern:UserInput(): nil
	self._maid:GiveBindAction("Light")
	ContextActionService:BindAction("Light", function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if input_state == Enum.UserInputState.Begin then
			print("LANTERN ACTION!")
			self._promise = self.Core.Utils.Promise.delay(CHARGE_DURATION)

			self._promise:andThen(function()
				self._maid.Animator:PlayAnimation(self._tool_data.AnimationData.Toggle)
				self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_lantern`):FireServer(TOGGLE_REMOTE_EVENT)
			end)
		else
			if self._promise then
				self._promise:cancel()
				self._promise = nil
			end
		end

		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.L)
	return
end

function Lantern:Destroy(): nil
	self._maid:DoCleaning()
	if self._promise then
		self._promise:cancel()
		self._promise = nil
	end
	self._tool_data = nil
	self._maid = nil
	self._tool = nil
	self = nil

	return
end

function Lantern.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, Lantern)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._maid = self.Core.Utils.Maid.new()

	if tool_data.AnimationData then
		self._maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	end

	self:UserInput()

	return self
end

return Lantern
