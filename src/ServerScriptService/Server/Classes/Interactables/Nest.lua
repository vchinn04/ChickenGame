local Nest = {}
Nest.__index = Nest
--[[
	<description>
		This class manages Nest interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		  Nest:Interact(player) ---> nil
			-- Called whenever interaction was successful.
			player: Player --> player doing the interaction

		 Nest:GetObject() ---> Instance?
			-- Returns the interactable instance

		Nest.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Nest
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable

		Nest:Destroy() ---> nil
			-- Cleanup Nest object
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"
local HEAL_AMOUNT: number = 45
--*************************************************************************************************--

function Nest:Interact(player: Player): nil
	-- local attacked_player: Player? = self.Core.Players:GetPlayerFromCharacter(self:GetObject())

	-- if not attacked_player then
	-- 	return
	-- end

	local player_object: {} = self.Core.DataManager.GetPlayerObject(player)

	if not player_object then
		return
	end

	-- self.Core.Fire("RemoveItem", player, self._data.ItemId)
	-- self.Core.DataManager.RemoveItem(player, "Items/" .. self._data.ItemId, 1)

	-- player_object:Heal(HEAL_AMOUNT)
	-- player_object:CancelBleeding()
	print("NEST INTERACTION!")
	local eggs = player_object:GetEggs()

	if #eggs <= 0 then
		print("NO EGGS!")
		return
	end

	for _, egg in eggs do
		print("ADD EGG: ", egg, " TO NEST!")
		self._total_value += self.Core.Utils.ItemDataManager.GetItem(egg).Value
	end

	print(self._total_value)

	player_object:ClearEggs()

	return
end

function Nest:GetObject(): Instance?
	return self._instance
end

function Nest:Destroy(): nil
	self._maid:DoCleaning()
	self._instance = nil
	self.Core = nil
	self._data = nil
	self._maid = nil
	self = nil
	return
end

function Nest.new(inst, Core, interaction_data): { [string]: any }
	local self = setmetatable({}, Nest)
	print("CREATED NEST!")
	self._instance = inst
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data
	self._total_value = 0

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

return Nest
