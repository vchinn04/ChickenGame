local Drop = {}
Drop.__index = Drop
--[[
	<description>
		This class manages drop interactables on the server.
	</description> 
	
	<API>
		Drop:Hold(player: Player) ---> nil
			-- Attach object to player character 
			player : Player --> the player holding 

		Drop:Pickup(player: Player) ---> nil
			-- Pick up the drop and destroy it 
			player : Player --> Player picking up the object 
			
		Drop:Interact(player) ---> nil
			-- Called whenever interaction was successful.
			player: Player --> player doing the interaction

		Drop:GetObject() ---> Instance?
			-- Returns the interactable instance

		Drop.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Resource
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable

		Drop:Destroy() ---> nil
			-- Cleanup Resource object
	</API>

	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"

--*************************************************************************************************--

function Drop:Hold(player: Player): nil
	if self:GetObject():GetAttribute("Locked") then -- Already claimed.
		return
	end

	local hold_attribute = self:GetObject():GetAttribute("Hold")
	if hold_attribute ~= nil and hold_attribute ~= player.Name then
		return
	end
	local player_object = self.Core.DataManager.GetPlayerObject(player) -- Get the player's PlayerClass instance

	if hold_attribute == player.Name then
		print("Player: " .. player.Name .. " dropped up a drop!")
		player_object:DetachObject(self:GetObject())
		self:GetObject():SetAttribute("Hold", nil)
	else
		self:GetObject():SetAttribute("Hold", player.Name)
		player_object:HoldItem(self:GetObject(), "Right Arm")
		print("Player: " .. player.Name .. " picked up a drop!")
	end

	return
end

function Drop:Pickup(player: Player): nil
	if self:GetObject():GetAttribute("Locked") then -- Already claimed.
		return
	end

	self:GetObject():SetAttribute("Locked", true)
	print("Player: " .. player.Name .. " Interaction on server!")
	if self._instance then
		local item_path = "Items/" .. self._item_key
		local tool_data: {} = self.Core.ItemDataManager.GetItem(self._item_key)

		self.Core.DataManager.AddItem(player, item_path)
		self.Core.DataManager.AddSpace(player, tool_data.Weight)

		self._instance:Destroy()
	end
	return
end

function Drop:Interact(player: Player, interact_function: string): nil
	if self[interact_function] then
		self[interact_function](self, player)
	end
	return
end

function Drop:GetObject(): Instance?
	return self._instance
end

function Drop.new(inst, Core, interaction_data): { [string]: any }
	print("New Server Drop!")
	local self = setmetatable({}, Drop)
	self._instance = inst
	self.Core = Core
	self._maid = Core.Utils.Maid.new()
	self._data = interaction_data
	self._item_key = inst:GetAttribute("Id")
	local pickup_prompt_data = {
		Duration = if interaction_data.PromptData then interaction_data.PromptData.Duration else 0,
		ObjectText = inst.Name,
		ActionText = "Pickup " .. inst.Name,
	}
	local hold_prompt_data = {
		KeyCode = Enum.KeyCode.F,
		Duration = if interaction_data.PromptData then interaction_data.PromptData.Duration else 0,
		ObjectText = inst.Name,
		ActionText = "Hold " .. inst.Name,
	}
	self._maid.PickupPromptManager =
		Core.Components[INTERACT_PROMPT_PATH].new(inst, interaction_data.Name, pickup_prompt_data, true, 0.95)
	self._maid.HoldPromptManager = Core.Components[INTERACT_PROMPT_PATH].new(inst, "Hold", hold_prompt_data, true, 0.95)

	return self
end

function Drop:Destroy(): nil
	print("Destroy Drop Server!")
	self._maid:DoCleaning()
	self._instance = nil
	self.Core = nil
	self._data = nil
	self._maid = nil
	self = nil
	return
end

return Drop
