local Nest = {}
Nest.__index = Nest
--[[
	<description>
		This class manages Nest interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		NestObj:Interact() ---> nil
			-- Called whenever interaction was successful.

		NestObj:Trigger() ---> nil
			-- Called whenever Nest was triggered.

		NestObj:TriggerEnd(): nil
			-- Called whenever Nest trigger ended.
		
		NestObj:GetObject() ---> Instance?
			-- Returns the interactable instance

		NestObj:GetPromptPart() ---> Instance?
			-- Returns the parent of the proximity prompt

		NestObj:Destroy() ---> nil
			-- Cleanup Nest object
			
		Nest.new(inst, Core, interaction_data) ---> { [string]: any } (NestObj)
			-- Create an instance of Nest
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"

local INTERACTION_SUCCESS_SERVER_EVENT = "InteractionSuccess"
local types = require(script.Parent.Parent.Parent.ClientTypes)
--*************************************************************************************************--

function Nest:Interact(): nil
	-- if self._data.EventDict and self._data.EventDict.Interact then
	-- 	self.Core.Fire(self._data.EventDict.Interact, self:GetPromptPart())
	-- else
	-- 	self.Core.Fire(INTERACTION_SUCCESS_SERVER_EVENT, self:GetPromptPart())
	-- end

	self.Core.Utils.Net:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT):FireServer(self:GetObject(), self._data.Id)
	-- self.Core.HumanoidRootPart.CFrame.LookVector

	return
end

function Nest:Trigger(): nil
	-- if self._data.TriggerEvent then
	-- 	self.Core.Fire(self._data.TriggerEvent, true, self:GetPromptPart())
	-- else
	-- 	self.Core.Fire("NestTrigger", true, self:GetPromptPart())
	-- end

	-- self.Core.Fire("NestTriggerTool", true, self:GetPromptPart())

	return
end

function Nest:TriggerEnd(): nil
	-- if self._data.TriggerEvent then
	-- 	self.Core.Fire(self._data.TriggerEvent, false, self:GetPromptPart())
	-- else
	-- 	self.Core.Fire("NestTrigger", false, self:GetPromptPart())
	-- end
	-- self.Core.Fire("NestTriggerTool", false, self:GetPromptPart())

	return
end

function Nest:GetObject(): Instance?
	return self._instance
end

function Nest:GetPromptPart(): Instance?
	if not self._maid or not self._maid.PromptManager then
		return
	end

	return self._maid.PromptManager:GetPromptParent()
end

function Nest:Destroy(): nil
	self._maid:DoCleaning()
	self._instance = nil
	self._data = nil
	self._maid = nil
	self.Core = nil
	self = nil
	return
end

function Nest.new(inst, Core, interaction_data: types.InteractionData): types.NestObject
	local self: types.NestObject = setmetatable({} :: types.NestObject, Nest)
	self._instance = inst
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data
	self._maid.PromptManager = Core.Components[INTERACT_PROMPT_PATH].new(
		inst,
		interaction_data.Name,
		Core.InteractionStateManager:getState()[interaction_data.RequiredEvent]
	)

	-- Core.InteractionManager.SetDefault("Trigger", inst, interaction_data.Id, self, self.Trigger)
	-- Core.InteractionManager.SetDefault("TriggerEnd", inst, interaction_data.Id, self, self.TriggerEnd)

	self._maid:GiveTask(Core.InteractionStateManager.changed:connect(function(newState, _)
		print("NEST STATE: ", newState[interaction_data.RequiredEvent] and not newState.Hold)
		self._maid.PromptManager:SetPromptEnabled(newState[interaction_data.RequiredEvent] and not newState.Hold)
	end))

	-- self._maid:GiveTask(self._instance:GetAttributeChangedSignal("Locked"):Connect(function()
	-- 	local interaction_state: {} = Core.InteractionStateManager:getState()
	-- 	self._maid.PromptManager:SetPromptEnabled(
	-- 		interaction_state[interaction_data.RequiredEvent]
	-- 			and not interaction_state.Hold
	-- 			and not self._instance:GetAttribute("Locked")
	-- 	)
	-- end))

	return self
end

return Nest
