local Revivable = {}
Revivable.__index = Revivable
--[[
	<description>
		This class manages Revivable interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		Revivable:Interact(player) ---> nil
			-- Called whenever interaction was successful.
			player: Player --> player doing the interaction

		Revivable:GetObject() ---> Instance?
			-- Returns the interactable instance

		Revivable.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Revivable
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable

		Revivable:Destroy() ---> nil
			-- Cleanup Revivable object
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"

--*************************************************************************************************--

function Revivable:Interact(player: Player): nil
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

	local player_cframe = player_object:GetCFrame()

	player_object:SpawnPlayer(player_cframe)

	return
end

function Revivable:GetObject(): Instance?
	return self._instance
end

function Revivable:Destroy(): nil
	self._maid:DoCleaning()
	self._instance = nil
	self.Core = nil
	self._data = nil
	self._maid = nil
	self = nil
	return
end

function Revivable.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Revivable)

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

return Revivable
