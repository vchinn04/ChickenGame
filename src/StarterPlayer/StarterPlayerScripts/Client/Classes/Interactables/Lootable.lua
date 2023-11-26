local Lootable = {}
Lootable.__index = Lootable
--[[
	<description>
		This class manages looting interaction on the client. See LootingUI as well.
	</description> 
	
	<API>
        LootableObj:Interact() ---> nil
			-- Called whenever interaction was successful.

		Lootable:Register() ---> nil
			-- Register player on server to the active looters. Needed to get looted player's data.
		
		Lootable:ClaimItem(item_id: string) ---> nil
			-- Attempt to take an item from looted player's inventory. 
			item_id: string -- ID of item being looted. 
			
		LootableObj:GetObject() ---> Instance?
			-- Returns the interactable instance

		LootableObj:GetPromptPart() ---> Instance?
			-- Returns the parent of the proximity prompt

		LootableObj:Destroy() ---> nil
			-- Cleanup Resource object

		Lootable.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Lootable
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

function Lootable:Interact(): nil
	self.Core.Fire("OpenUI", self._data.UI, self)
	return
end

function Lootable:Register(): nil
	self.Core.Utils.Net
		:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT)
		:FireServer(self:GetObject(), self._data.Id, "Register")
	return
end

function Lootable:ClaimItem(item_id: string): nil
	self.Core.Utils.Net
		:RemoteEvent(INTERACTION_SUCCESS_SERVER_EVENT)
		:FireServer(self:GetObject(), self._data.Id, "Claim", { ItemId = item_id })
	return
end

function Lootable:GetObject(): Instance?
	return self._instance
end

function Lootable:GetPromptPart(): Instance?
	if not self._maid or not self._maid.PickupPromptManager then
		return
	end

	return self._maid.PickupPromptManager:GetPromptParent()
end

function Lootable:GetPlayer(): Player?
	return self._player
end

function Lootable:Destroy(): nil
	print("Destroy Lootable Client!")
	self._maid:DoCleaning()
	self._instance = nil
	self._maid = nil
	self._data = nil
	self.Core = nil
	self = nil
	return
end

function Lootable.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Lootable)
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._instance = inst
	self._is_holding = false
	self._data = interaction_data
	self._player = Core.Players:GetPlayerFromCharacter(inst)

	self._maid.PickupPromptManager = Core.Components[INTERACT_PROMPT_PATH].new(inst, interaction_data.Name)

	if interaction_data.IgnoreSelf and inst.Name == self.Core.Player.Name then
		self._maid.PickupPromptManager:SetPromptEnabled(false)
	end

	return self
end

return Lootable
