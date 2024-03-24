local PlatypusHat = {}
PlatypusHat.__index = PlatypusHat
--[[
	<description>
		This class provides the functionalities for a PlatypusHat
	</description> 
	
	<API>
		PlatypusHatObj:SkillHandler(): nil
			-- Handle input and client side of skill

		PlatypusHatObj:GetId()
			-- Returns id of tool assigned to instance

		PlatypusHatObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		PlatypusHat.new(tool_obj: Tool, tool_data: { [string]: any }) --> PlatypusHatObj
			-- Creates a PlatypusHat given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local ContextActionService = game:GetService("ContextActionService")
local types = require(script.Parent.Parent.Parent.ClientTypes)

--*************************************************************************************************--
function PlatypusHat:SkillHandler(): nil
	self._maid:GiveBindAction("HatSkill")
	ContextActionService:BindAction("HatSkill", function(_, input_state)
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if input_state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end

		if self._tool:GetAttribute("IsActive") then
			return Enum.ContextActionResult.Pass
		end

		if self._maid.CooldownManager:CheckCooldown("Skill") then
			print("SKILL COOLDOWN")
			return Enum.ContextActionResult.Pass
		end

		self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_hat`):FireServer("HatSkill")
		return
	end, true, Enum.KeyCode.Q)

	self._maid:GiveTask(self._tool:GetAttributeChangedSignal("IsActive"):Connect(function()
		local status: boolean = self._tool:GetAttribute("IsActive")
		if not status then
			self._maid.CooldownManager:OneTimeCooldown("Skill", 3)
			return
		end
		return
	end))

	return
end

function PlatypusHat:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function PlatypusHat:Destroy(): nil
	print("DESTROY PIGGY HAT")
	self._maid:DoCleaning()
	self._maid = nil
	self._tool_data = nil
	self._tool = nil
	self = nil
	return
end

function PlatypusHat.new(tool_obj: Tool, tool_data: types.ToolData): types.PlatypusHatObject
	local self: types.PlatypusHatObject = setmetatable({} :: types.PlatypusHatObject, PlatypusHat)
	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj
	self._maid = self.Core.Utils.Maid.new()
	self._maid.CooldownManager = self.Core.CooldownClass.new({ { "Skill", 0.15 } })
	print("CREATE PIGGY HAT")
	self:SkillHandler()

	return self
end

return PlatypusHat
