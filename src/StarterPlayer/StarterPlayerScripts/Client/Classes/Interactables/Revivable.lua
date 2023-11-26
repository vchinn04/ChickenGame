local Revivable = {}
Revivable.__index = Revivable
--[[
	<description>
		This class manages Revivable interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		RevivableObj:Interact() ---> nil
			-- Called whenever interaction was successful.

		RevivableObj:Trigger() ---> nil
			-- Called whenever Revivable was triggered.

		RevivableObj:TriggerEnd(): nil
			-- Called whenever Revivable trigger ended.
		
		RevivableObj:GetObject() ---> Instance?
			-- Returns the interactable instance

		RevivableObj:GetPromptPart() ---> Instance?
			-- Returns the parent of the proximity prompt

		RevivableObj:Destroy() ---> nil
			-- Cleanup Revivable object
			
		Revivable.new(inst, Core, interaction_data) ---> { [string]: any } (RevivableObj)
			-- Create an instance of Revivable
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

function Revivable:Interact(): nil
	if self._data.EventDict and self._data.EventDict.Interact then
		self.Core.Fire(self._data.EventDict.Interact, self:GetPromptPart())
	else
		self.Core.Fire(INTERACTION_SUCCESS_SERVER_EVENT, self:GetPromptPart())
	end

	self.Core.Utils.Net:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT):FireServer(self:GetObject(), self._data.Id)

	return
end

function Revivable:Trigger(): nil
	return
end

function Revivable:TriggerEnd(): nil
	return
end

function Revivable:GetObject(): Instance?
	return self._instance
end

function Revivable:GetPromptPart(): Instance?
	if not self._maid or not self._maid.PromptManager then
		return
	end

	return self._maid.PromptManager:GetPromptParent()
end

function Revivable:Destroy(): nil
	print("Cleaning!")
	self._maid:DoCleaning()
	self._instance = nil
	self._data = nil
	self._maid = nil
	self.Core = nil
	self = nil
	return
end

function Revivable.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Revivable)
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

	return self
end

return Revivable
