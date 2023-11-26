local UIInteractable = {}
UIInteractable.__index = UIInteractable
--[[
	<description>
		This class manages UI interactables on the client.
	</description> 
	
	<API>
		UIInteractableObj:Interact() ---> nil
			-- Fire an open ui event for associated UI 

		UIInteractableObj:GetObject() ---> Instance?
			-- return the intractable object 

		UIInteractableObj:GetPromptPart() ---> Instance?
			-- return the prompt part
			
		UIInteractable.new(inst, Core, interaction_data) ---> UIInteractableObj
			-- create and return UIInteractableObj
			inst: Instance -- interactable object
			Core: { [string]: any } -- Core
			interaction_data: { [string]: any } -- Data of interactable
	</API>

	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"

--*************************************************************************************************--

function UIInteractable:Interact(): nil
	self.Core.Fire("OpenUI", self._data.UI, self._data.UIProps)
	return
end

function UIInteractable:GetObject(): Instance?
	return self._instance
end

function UIInteractable:GetPromptPart(): Instance?
	if not self._maid or not self._maid.PickupPromptManager then
		return
	end

	return self._maid.PickupPromptManager:GetPromptParent()
end

function UIInteractable.new(
	inst: Instance,
	Core: { [string]: any },
	interaction_data: { [string]: any }
): { [string]: any }
	local self = setmetatable({}, UIInteractable)
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._instance = inst
	self._is_holding = false
	self._data = interaction_data

	self._maid.PickupPromptManager = Core.Components[INTERACT_PROMPT_PATH].new(inst, interaction_data.Name)

	if interaction_data.IgnoreSelf and inst.Name == self.Core.Player.Name then
		self._maid.PickupPromptManager:SetPromptEnabled(false)
	end

	return self
end

function UIInteractable:Destroy(): nil
	print("Destroy UIInteractable Client!")
	self._maid:DoCleaning()
	self._instance = nil
	self._maid = nil
	self._data = nil
	self.Core = nil
	self = nil
	return
end

return UIInteractable
