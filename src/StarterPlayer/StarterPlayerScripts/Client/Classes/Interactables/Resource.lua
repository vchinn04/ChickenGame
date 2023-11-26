local Resource = {}
Resource.__index = Resource
--[[
	<description>
		This class manages resource interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		ResourceObj:Interact() ---> nil
			-- Called whenever interaction was successful.

		ResourceObj:Trigger() ---> nil
			-- Called whenever resource was triggered.

		ResourceObj:TriggerEnd(): nil
			-- Called whenever resource trigger ended.
		
		ResourceObj:GetObject() ---> Instance?
			-- Returns the interactable instance

		ResourceObj:GetPromptPart() ---> Instance?
			-- Returns the parent of the proximity prompt

		ResourceObj:Destroy() ---> nil
			-- Cleanup Resource object
			
		Resource.new(inst, Core, interaction_data) ---> { [string]: any } (ResourceObj)
			-- Create an instance of Resource
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

--*************************************************************************************************--

function Resource:Interact(): nil
	if self._data.EventDict and self._data.EventDict.Interact then
		self.Core.Fire(self._data.EventDict.Interact, self:GetPromptPart())
	else
		self.Core.Fire(INTERACTION_SUCCESS_SERVER_EVENT, self:GetPromptPart())
	end

	self.Core.Utils.Net
		:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT)
		:FireServer(self:GetObject(), self._data.Id, self.Core.HumanoidRootPart.CFrame.LookVector)

	return
end

function Resource:Trigger(): nil
	if self._data.TriggerEvent then
		self.Core.Fire(self._data.TriggerEvent, true, self:GetPromptPart())
	else
		self.Core.Fire("ResourceTrigger", true, self:GetPromptPart())
	end

	self.Core.Fire("ResourceTriggerTool", true, self:GetPromptPart())

	return
end

function Resource:TriggerEnd(): nil
	if self._data.TriggerEvent then
		self.Core.Fire(self._data.TriggerEvent, false, self:GetPromptPart())
	else
		self.Core.Fire("ResourceTrigger", false, self:GetPromptPart())
	end
	self.Core.Fire("ResourceTriggerTool", false, self:GetPromptPart())

	return
end

function Resource:GetObject(): Instance?
	return self._instance
end

function Resource:GetPromptPart(): Instance?
	if not self._maid or not self._maid.PromptManager then
		return
	end

	return self._maid.PromptManager:GetPromptParent()
end

function Resource:Destroy(): nil
	self._maid:DoCleaning()
	self._instance = nil
	self._data = nil
	self._maid = nil
	self.Core = nil
	self = nil
	return
end

function Resource.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Resource)
	self._instance = inst
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data
	self._maid.PromptManager = Core.Components[INTERACT_PROMPT_PATH].new(
		inst,
		interaction_data.Name,
		Core.InteractionStateManager:getState()[interaction_data.RequiredEvent]
	)

	Core.InteractionManager.SetDefault("Trigger", inst, interaction_data.Id, self, self.Trigger)
	Core.InteractionManager.SetDefault("TriggerEnd", inst, interaction_data.Id, self, self.TriggerEnd)

	self._maid:GiveTask(Core.InteractionStateManager.changed:connect(function(newState, _)
		self._maid.PromptManager:SetPromptEnabled(newState[interaction_data.RequiredEvent] and not newState.Hold)
	end))

	self._maid:GiveTask(self._instance:GetAttributeChangedSignal("Locked"):Connect(function()
		local interaction_state: {} = Core.InteractionStateManager:getState()
		self._maid.PromptManager:SetPromptEnabled(
			interaction_state[interaction_data.RequiredEvent]
				and not interaction_state.Hold
				and not self._instance:GetAttribute("Locked")
		)
	end))

	return self
end

return Resource
