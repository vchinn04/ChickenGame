local UIInteractable = {}
UIInteractable.__index = UIInteractable
--[[
	<description>
		This class manages UI interactables. There is no functionality on server.
	</description> 
	
	<API>
     
	</API>

	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"

--*************************************************************************************************--

function UIInteractable:Interact(): nil
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

function UIInteractable.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, UIInteractable)
	self._instance = inst
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data

	local ui_prompt_data = {
		KeyCode = if interaction_data.PromptData and interaction_data.PromptData.KeyCode
			then interaction_data.PromptData.KeyCode
			else Enum.KeyCode.E,

		Duration = if interaction_data.PromptData and interaction_data.PromptData.Duration
			then interaction_data.PromptData.Duration
			else 0,

		ObjectText = if interaction_data.PromptData and interaction_data.PromptData.ObjectText
			then interaction_data.PromptData.ObjectText
			else inst.Name,

		ActionText = if interaction_data.PromptData and interaction_data.PromptData.ActionPrefix
			then interaction_data.PromptData.ActionPrefix .. inst.Name
			else "Open " .. inst.Name,
	}

	self._maid.PickupPromptManager =
		Core.Components[INTERACT_PROMPT_PATH].new(inst, interaction_data.Name, ui_prompt_data, true, 0.95)

	return self
end

function UIInteractable:Destroy(): nil
	print("Destroy Drop Client!")
	self._maid:DoCleaning()
	self._instance = nil
	self._maid = nil
	self._data = nil
	self.Core = nil
	self = nil
	return
end

return UIInteractable
