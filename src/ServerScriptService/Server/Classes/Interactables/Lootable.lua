local Lootable = {}
Lootable.__index = Lootable
--[[
	<description>
		This class manager lootable (player) objects.
	</description> 
	
	<API>
		Lootable:Register(player: Player) ---> nil
			-- Add player to the _registered_players list and share the looted player's 
			data 
			player : Player --> Player being registered

		Lootable:Unregister(player: Player) ---> nil
			-- Remove the looted player's replica from player
			player : Player --> Player being unregistered

		Lootable:Claim(player: Player, props: { [string]: any }): Instance?
			-- Transfer item from looted player to player doing the looting 
			player : Player --> Player to whome item is being transferred 
			props : { [string]: any } --> Props passed from clinet (ItemId entry is id of item being looted)
		Lootable:Interact(player) ---> nil
			-- Called whenever interaction was successful.
			player: Player --> player doing the interaction

		Lootable:GetObject() ---> Instance?
			-- Returns the interactable instance

		Lootable.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Resource
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable

		Lootable:Destroy() ---> nil
			-- Cleanup Resource object
	</API>

	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT = require(script.Parent.Components.InteractPrompt)

--*************************************************************************************************--
function Lootable:Register(player: Player): nil
	print("Register player")
	if self._registered_players and not self._registered_players[player] then
		self.Core.DataManager.ShareReplica(self._player, player)
		self._registered_players[player] = true
	end
	return
end

function Lootable:Unregister(player: Player): nil
	print("Unregister player")
	self.Core.DataManager.RemoveReplicaConsumer(self._player, player)
	return
end

function Lootable:Claim(player: Player, props: { [string]: any }): Instance?
	local item_entry = self.Core.Utils.ItemDataManager.GetItem(props.ItemId)
	if not item_entry then
		return
	end

	self.Core.Fire("RemoveItem", self._player, item_entry.Name)
	self.Core.DataManager.AddItem(player, "Items/" .. props.ItemId)
	self.Core.DataManager.RemoveItem(self._player, "Items/" .. props.ItemId)
end

function Lootable:Interact(player: Player, interact_function: string, props: { [string]: any }?): nil
	print("Looting Interaction!")
	if self[interact_function] then
		self[interact_function](self, player, props)
	end
	return
end

function Lootable:GetObject(): Instance?
	return self._instance
end

function Lootable.new(inst, Core, interaction_data): { [string]: any }
	print("New Server Drop!")
	local self = setmetatable({}, Lootable)
	self._instance = inst
	self._player = Core.Players:GetPlayerFromCharacter(inst)
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data
	self._registered_players = {}

	local lootable_prompt_data = {
		KeyCode = if interaction_data.PromptData and interaction_data.PromptData.KeyCode
			then interaction_data.PromptData.KeyCode
			else Enum.KeyCode.E,

		Duration = if interaction_data.PromptData and interaction_data.PromptData.Duration
			then interaction_data.PromptData.Duration
			else 0,

		ObjectText = if interaction_data.PromptData and interaction_data.PromptData.ObjectText
			then interaction_data.PromptData.ObjectText
			else inst.Name,

		ActionText = "Loot " .. inst.Name,
	}

	self._maid.PickupPromptManager = INTERACT_PROMPT.new(inst, interaction_data.Name, lootable_prompt_data, true, 0.95)

	return self
end

function Lootable:Destroy(): nil
	print("Destroy Lootable Server!")
	self.Core.DataManager.RemoveReplicaConsumerList(self._player, self._registered_players)
	self._maid:DoCleaning()
	self._registered_players = nil
	self._instance = nil
	self.Core = nil
	self._data = nil
	self._maid = nil
	self = nil
	return
end

return Lootable
