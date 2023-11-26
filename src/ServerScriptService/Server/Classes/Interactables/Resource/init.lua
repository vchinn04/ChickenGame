local Resource = {}
Resource.__index = Resource
local InteractFunctions = require(script:WaitForChild("InteractFunctions"))
--[[
	<description>
		This class manages resource interactables (Trees, Ores, etc) on the server.
	</description> 
	
	<API>
		  Resource:Interact(player) ---> nil
			-- Called whenever interaction was successful.
			player: Player --> player doing the interaction

		 Resource:GetObject() ---> Instance?
			-- Returns the interactable instance

		Resource.new(inst, Core, interaction_data) ---> { [string]: any }
			-- Create an instance of Resource
			inst : Instance ---> Interactable instance
			Core : { [string]: any } ---> Core dictionary
			interaction_data : > { [string]: any } ---> Data for the interactable

		Resource:Destroy() ---> nil
			-- Cleanup Resource object
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local ITEM_SPACING = 2
local INTERACT_PROMPT_PATH = "Misc/InteractPrompt"

--*************************************************************************************************--

function Resource:Interact(player: Player, direction: Vector3?): nil
	if self:GetObject():GetAttribute("Locked") then -- Not interactable
		return
	end

	self:GetObject():SetAttribute("Locked", true)
	print("Player: " .. player.Name .. " Interaction on server!")

	local drop_item = self._data.ItemDrop
	local drop_amount = if self._data.DropAmount == "random"
		then math.random(self._data.DropChances[1], self._data.DropChances[2])
		else self._data.DropAmount

	if not drop_amount then
		drop_amount = 1
	end

	if not direction then
		direction = Vector3.new(0, 0, 1)
	end

	direction = Vector3.new(direction.X, 0, direction.Z)
	direction = direction.Unit

	local drop_location = self._instance:GetPivot().Position
		+ Vector3.new(direction.X, -self._instance:GetExtentsSize().Y / 2.5, direction.Z)

	for _ = 1, drop_amount, 1 do
		self.Core.InteractionManager.CreateDrop(drop_item, drop_location)
		drop_location += direction * ITEM_SPACING
	end

	if self._success_sound then
		self._maid.SoundObject:Play(self._success_sound)
	end

	self._effect_function(self.Core, self:GetObject(), true)

	self.Core.Utils.Promise.delay(self._data.RespawnDuration):andThen(function()
		self._effect_function(self.Core, self:GetObject(), false)
		self:GetObject():SetAttribute("Locked", false)
	end)

	return
end

function Resource:GetObject(): Instance?
	return self._instance
end

function Resource.new(inst, Core, interaction_data): { [string]: any }
	print("New Server Resource!")
	local self = setmetatable({}, Resource)
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

	self._effect_function = InteractFunctions[self._data.Id]
	if not self._effect_function then
		self._effect_function = InteractFunctions.Default
	end

	return self
end

function Resource:Destroy(): nil
	self._maid:DoCleaning()
	self._instance = nil
	self.Core = nil
	self._data = nil
	self._maid = nil
	self = nil
	return
end

return Resource
