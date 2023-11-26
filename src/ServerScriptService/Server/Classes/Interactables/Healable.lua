local Healable = {}
Healable.__index = Healable
--[[
	<description>
		This class manages Healable interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		  Healable:Interact(player) ---> nil
			-- Called whenever interaction was successful.
			player: Player --> player doing the interaction

		 Healable:GetObject() ---> Instance?
			-- Returns the interactable instance

		Healable.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Healable
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable

		Healable:Destroy() ---> nil
			-- Cleanup Healable object
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"
local HEAL_AMOUNT: number = 45
--*************************************************************************************************--

function Healable:Interact(player: Player): nil
	local attacked_player: Player? = self.Core.Players:GetPlayerFromCharacter(self:GetObject())

	if not attacked_player then
		return
	end

	local player_object: {} = self.Core.DataManager.GetPlayerObject(attacked_player)

	if not player_object then
		return
	end

	self.Core.Fire("RemoveItem", player, self._data.ItemId)
	self.Core.DataManager.RemoveItem(player, "Items/" .. self._data.ItemId, 1)

	player_object:Heal(HEAL_AMOUNT)
	player_object:CancelBleeding()

	return
end

function Healable:GetObject(): Instance?
	return self._instance
end

function Healable:Destroy(): nil
	self._maid:DoCleaning()
	self._instance = nil
	self.Core = nil
	self._data = nil
	self._maid = nil
	self = nil
	return
end

function Healable.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Healable)

	self._instance = inst
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data

	self._maid.PromptManager =
		Core.Components[INTERACT_PROMPT_PATH].new(inst, interaction_data.Name, interaction_data.PromptData)

	if self._data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._data.SoundPath)
		if self._data.SoundData.Server.Success then
			self._success_sound =
				self._maid.SoundObject:CloneSound(self._data.SoundData.Server.Success.Name, self._instance)
		end
	end

	return self
end

return Healable
