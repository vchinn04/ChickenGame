local Drop = {}
Drop.__index = Drop
--[[
	<description>
		This class manages drop interactables on the client.
	</description> 
	
	<API>
        DropObj:Interact() ---> nil
			-- Called whenever interaction was successful.

		DropObj:Hold() ---> nil
			-- Fire Hold event to attempt to hold object. 

		DropObj:GetObject() ---> Instance?
			-- Returns the interactable instance

		DropObj:GetPromptPart() ---> Instance?
			-- Returns the parent of the proximity prompt

		DropObj:Destroy() ---> nil
			-- Cleanup Resource object

		Drop.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Drop
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

function Drop:Interact(): nil
	self.Core.Fire("DropInteraction", self._instance)
	self.Core.Utils.UtilityFunctions.MakeTransparent(self._instance)
	self.Core.Utils.Net
		:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT)
		:FireServer(self:GetObject(), self._data.Id, "Pickup")
	return
end

function Drop:Hold(): nil
	self.Core.Utils.Net
		:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT)
		:FireServer(self:GetObject(), self._data.Id, "Hold")
	return
end

function Drop:GetObject(): Instance?
	return self._instance
end

function Drop:GetPromptPart(): Instance?
	if not self._maid or not self._maid.PickupPromptManager then
		return
	end

	return self._maid.PickupPromptManager:GetPromptParent()
end

function Drop.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Drop)
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._instance = inst
	self._is_holding = false
	self._data = interaction_data
	self._maid.PickupPromptManager = Core.Components[INTERACT_PROMPT_PATH].new(inst, interaction_data.Name)
	self._maid.HoldPromptManager = Core.Components[INTERACT_PROMPT_PATH].new(inst, "Hold")

	Core.InteractionManager.SetDefault("Default", inst, "Hold", self, self.Hold)

	self._maid:GiveTask(Core.InteractionStateManager.changed:connect(function(newState, _)
		local hold_status = self._instance:GetAttribute("Hold")
		local player_is_holding = hold_status == Core.Player.Name
		self._maid.PickupPromptManager:SetPromptEnabled(not newState.Hold or player_is_holding)
		self._maid.HoldPromptManager:SetPromptEnabled(not newState.Hold or player_is_holding)
	end))

	self._maid:GiveTask(self._instance:GetAttributeChangedSignal("Hold"):Connect(function()
		local hold_status: boolean = self._instance:GetAttribute("Hold")
		local player_is_holding: boolean = hold_status == Core.Player.Name
		local prompt_status: boolean = hold_status == nil or player_is_holding
		local hold_text: string = player_is_holding and `Drop {self:GetObject().Name}` or `Hold {self:GetObject().Name}`
		local pickup_text: string = player_is_holding and `Take {self:GetObject().Name}`
			or `Pickup {self:GetObject().Name}`

		if player_is_holding then
			self._is_holding = true
			Core.Fire("HoldInteraction", true)
		elseif self._is_holding then
			self._is_holding = false
			Core.Fire("HoldInteraction", false)
		end
		self._maid.PickupPromptManager:SetPromptEnabled(prompt_status)
		self._maid.HoldPromptManager:SetPromptEnabled(prompt_status)
		self._maid.PickupPromptManager:SetPromptActionText(pickup_text)
		self._maid.HoldPromptManager:SetPromptActionText(hold_text)
	end))

	return self
end

function Drop:Destroy(): nil
	print("Destroy Drop Client!")
	self._maid:DoCleaning()
	self._instance = nil
	self._maid = nil
	if self._is_holding then
		self.Core.Fire("HoldInteraction", false)
	end
	self._is_holding = nil
	self._data = nil
	self.Core = nil
	self = nil
	return
end

return Drop
