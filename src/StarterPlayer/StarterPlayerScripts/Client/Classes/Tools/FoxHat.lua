local FoxHat = {}
FoxHat.__index = FoxHat
--[[
	<description>
		This class provides the functionalities for a FoxHat
	</description> 
	
	<API>
		FoxHatObj:GetId()
			-- Returns id of tool assigned to instance

		FoxHatObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		FoxHat.new(tool_obj: Tool, tool_data: { [string]: any }) --> FoxHatObj
			-- Creates a FoxHat given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local ContextActionService = game:GetService("ContextActionService")

--*************************************************************************************************--

function FoxHat:SkillHandler()
	self._maid:GiveBindAction("HatSkill")
	ContextActionService:BindAction("HatSkill", function(_, input_state)
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if input_state == Enum.UserInputState.Begin then
			print("FOX SKILL!")
			self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_hat`):FireServer("HatSkill")
		end
	end, true, Enum.KeyCode.Q)

	self._maid:GiveBindAction("Steal")
	ContextActionService:BindAction("Steal", function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if input_state == Enum.UserInputState.Begin then
			print("STEAL!")
			self.RaycastParams.FilterDescendantsInstances = { self.Core.Character }

			local orientation, size = self.Core.Character:GetBoundingBox()

			local res = workspace:Blockcast(
				orientation,
				size,
				self.Core.HumanoidRootPart.CFrame.LookVector * size.Z,
				self.RaycastParams
			)
			print(res)
		end

		return
	end, true, Enum.UserInputType.MouseButton1)
end

function FoxHat:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function FoxHat:Destroy(): nil
	self.Core.Fire("EnableDoubleJump", "FoxHat", false)
	print("DESTROY FOX HAT")
	self._maid:DoCleaning()
	self._maid = nil
	self._tool_data = nil
	self._tool = nil
	self = nil
	return
end

function FoxHat.new(tool_obj: Tool, tool_data: { [string]: any }): {}
	local self = setmetatable({}, FoxHat)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj
	self._maid = self.Core.Utils.Maid.new()
	self.Core.Fire("EnableDoubleJump", "FoxHat", true)
	print("CREATE FOX HAT")
	self:SkillHandler()

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RaycastParams.FilterDescendantsInstances = { self.Core.Character }
	self.RaycastParams.CollisionGroup = "Players"
	self.Acceleration = self.Core.GRAVITY_VECTOR

	return self
end

return FoxHat
