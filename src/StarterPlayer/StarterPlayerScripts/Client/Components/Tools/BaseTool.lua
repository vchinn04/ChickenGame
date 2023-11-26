local BaseTool = {}
BaseTool.__index = BaseTool
--[[
	<description>
		This class provides the shared functionalities of most if not all tools. 
	</description> 
	
	<API>
		BaseTool.new() --> ToolObj
			-- Creates a BaseTool given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
			
		BaseTool:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		BaseTool:Unequip() --> void
			-- Tares down connections such as input, etc
			
		BaseTool:Destroy() --> void
			-- Tares down all connections and destroys components used 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function BaseTool:Equip(): nil
	if self._tool_data.AnimationData.Equip then
		local anim: AnimationTrack = self.Animator:PlayAnimation(self._tool_data.AnimationData.Equip)
		self._connection_maid:GiveTask(anim.Stopped:Connect(function()
			if self._tool_data.AnimationData.Idle then
				self.Animator:PlayAnimation(self._tool_data.AnimationData.Idle)
			end
		end))
	elseif self._tool_data.AnimationData.Idle then
		self.Animator:SetPriority(self._tool_data.AnimationData.Idle, Enum.AnimationPriority.Core)
		self.Animator:PlayAnimation(self._tool_data.AnimationData.Idle)
	end
	return
end

function BaseTool:Unequip(): nil
	self._connection_maid:DoCleaning()
	self.Animator:DoCleaning()
	return
end

function BaseTool.new(tool_obj: Tool, tool_data: { [string]: any }, anim_handler): SwordType
	local self = setmetatable({}, BaseTool)

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self.Animator = anim_handler

	return self
end

function BaseTool:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()
	self._connection_maid = nil
	self.Animator = nil
	self._core_maid = nil
	self = nil
	return
end

return BaseTool
