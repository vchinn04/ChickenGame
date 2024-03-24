local PlayerClass = {}
PlayerClass.__index = PlayerClass
--[[
	<description>
		This class is responsible for handling functionalities tied with a player.
	</description> 
	
	<API>
		PlayerObject:AttachObject(object: Instance, item_id: string, dont_clone: boolean?) ---> nil
			-- Attach object as accessory to character
			object: Instance -- object to attach 
			item_id: string -- id of object 
			dont_clone: boolean? -- True: will not clone

		PlayerObject:HoldItem(object: Instance, attach_name: string) ---> nil
			-- Weld object to specified object in player character. 
			object: Instance -- the object to weld. A well of name player.Name will be added to object 
			attach_name: string -- the name of object in player to attach to 

	  	PlayerObject:DetachObject(object: Instance) ---> nil
			-- Detach object from player, by destroying the weld of name `player.Name`
			object: Instance -- Object to detach 

		PlayerObject:DoDamage(damage_amount : number, damage_message : string?) ---> nil
			-- Do damage to the player's Humanoid, display damage_message if applicable
			damage_amount : number -- Amount to damage by 

		PlayerObject:Heal(heal_amount: number, heal_message: string?) ---> boolean
			-- Heal the player unless already max health 
			heal_amount : number -- amount to heal by 
			Return true if successful else False

		PlayerObject:Knockback(duration: number, direction: Vector3) ---> nil
			-- Call the Knockback remote and pass the direction and duration of the Knockback
			duration : number -- Duration of the knockback
			direction : Vector3 -- Direction of knockback

		PlayerObject:Stun(duration: number) ---> nil
			-- Stun the player. Lock player's position in place for specified duration. 
			duration: number -- for how long to stun player 

		PlayerObject:IsStunned() ---> boolean
			-- Return the "Stun" attribute value 

		PlayerObject:RespawnTimer(): nil
			-- Trigger the respawn timer 

		PlayerObject:CleanRespawn(): nil
			-- Cancel the respawn timer 

		PlayerObject:GetPosition() ---> Vector3 
			-- Return the player's current position 

		PlayerObject:GetCFrame() ---> CFrame 
			-- Return the player's current HRP CFrame 

        PlayerObject:GetCharacter() ---> Model?
            -- Return the player's character 
            
        PlayerObject:GetHumanoid() ---> Humanoid?
            -- Return the player's humanoid
            
		PlayerObject:SpawnPlayer() ---> nil 
			-- Load player's Character 
			
		PlayerObject:HandleCharacter() ---> nil
			-- Get the player's character and humanoid and listen for death to perform cleanup.

		PlayerObject:UnequipAll() ---> nil
			-- Unequip any equipped tools
	
		PlayerObject:GetBasket(): types.BasketObject?
			-- Return an equipped tool if it is in Basket group (Basket Class)

		PlayerObject:EquipTool(tool_name: string) ---> nil
			-- Equip the tool specified. Unequip previously equipped tool first. 
			tool_name : string -- Name of the tool being equipped
			
		PlayerObject:UnequipTool(tool_name : string, tool_object : Tool) ---> nil
			-- Unequip the tool specified
			tool_name : string -- Name of the tool being unequipped

		PlayerObject:AddTool(tool_name: string, tool_object : Tool) ---> nil
			-- Add a tool object and unequip any tool on top of the toolstack if there if the max number of added tools is surpassed.
			tool_name : string -- Name of the tool being added
			tool_object :  {[string] : any} -- Instance of class for specified tool
			
		PlayerObject:RemoveTool(tool_name: string) ---> nil
			-- Remove a tool from player, destroy its resources.
			tool_name : string -- Name of the tool being removed
			
		PlayerObject:ResetTools() ---> nil
			-- Destroy the players current tool objects and re initialize them
			also recount space.

		PlayerObject:AddEgg(egg_id: string) ---> nil
			-- Add an egg to player's basket
			egg_id: string -- The id of the egg type to add to basket
	
		PlayerObject:GetEggs() ---> { string }
			-- Return list/stack of egg id's in player's basket

		PlayerObject:PopEggs(amount: number) ---> { string }?
			-- Pop specified amount of eggs from player's basket and return list of id's popped. If
			amount specified greater than the amount of eggs in basket, all of the eggs in basket 
			are popped. 
			amount: number -- Number of eggs to pop
			
		PlayerObject:StealEggs(amount: number) ---> { string }?
			-- Attempt to steal eggs from player. Only steals eggs if number of steal hits remaining is 0.
			amount: number -- Number of eggs attempt to stea;

		PlayerObject:ClearEggs() ---> nil
			-- Clear all of the eggs in player's basket

		PlayerObject:InitialLoading(): nil
			-- Add all items that are supposed to be equipped and calculate space taken. 

		PlayerObject:HandleCharacterAddition() ---> nil
			-- Listen for the addition of the player's character (such as after death) to 
			-- setup the neccessary connections. 

		PlayerObject:AddEgg(egg_id: string) ---> nil
			-- Add an egg to player's basket
			egg_id: string -- The id of the egg type to add to basket
	
		PlayerObject:GetEggs() ---> { string }
			-- Return list/stack of egg id's in player's basket

		PlayerObject:PopEggs(amount: number) ---> { string }?
			-- Pop specified amount of eggs from player's basket and return list of id's popped. If
			amount specified greater than the amount of eggs in basket, all of the eggs in basket 
			are popped. 
			amount: number -- Number of eggs to pop
			
		PlayerObject:StealEggs(amount: number) ---> { string }?
			-- Attempt to steal eggs from player. Only steals eggs if number of steal hits remaining is 0.
			amount: number -- Number of eggs attempt to stea;

		PlayerObject:ClearEggs() ---> nil
			-- Clear all of the eggs in player's basket
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local CollectionService = game:GetService("CollectionService")

local TimedFunction = nil

local types = require(script.Parent.Parent.ServerTypes)

local EggHandler = require(script.Components.EggHandler)
local ToolHandler = require(script.Components.ToolHandler)
local CharacterHandler = require(script.Components.CharacterHandler)

local RESPAWN_TIMER: number = 10

--*************************************************************************************************--

----------------CHARACTER HANDLER------------------
function PlayerClass:AttachObject(object: Instance, item_id: string, dont_clone: boolean?): nil
	self._character_handler:AttachObject(object, item_id, dont_clone)
	return
end

function PlayerClass:HoldItem(object: Model, attach_name: string): nil
	self._character_handler:HoldItem(object, attach_name)
	return
end

function PlayerClass:DetachObject(object: Instance): nil
	self._character_handler:DetachObject(object)
	return
end

function PlayerClass:DoDamage(
	damage_amount: number,
	damage_message: string?,
	damage_part_name: string?,
	damage_impulse: Vector3
): nil
	self._character_handler:DoDamage(damage_amount, damage_message, damage_part_name, damage_impulse)
	return
end

function PlayerClass:Heal(heal_amount: number, heal_message: string?): boolean
	return self._character_handler:Heal(heal_amount, heal_message)
end

function PlayerClass:Knockback(duration: number, direction: Vector3, force: number?): nil
	self.Core.Utils.Net:RemoteEvent("Knockback"):FireClient(self._player, direction.Unit, force, duration)
	return
end

function PlayerClass:Stun(duration: number): nil
	self._character_handler:Stun(duration)
	return
end

function PlayerClass:IsStunned(): boolean
	return self._character_handler:IsStunned()
end

function PlayerClass:GetPosition(): Vector3
	return self._character_handler:GetPosition()
end

function PlayerClass:GetCFrame(): CFrame
	return self._character_handler:GetCFrame()
end

function PlayerClass:GetCharacter(): Model
	return self._character_handler:GetCharacter()
end

function PlayerClass:GetHumanoid(): Humanoid?
	return self._character_handler:GetHumanoid()
end

function PlayerClass:HandleCharacter(): nil
	local spawn_position: CFrame? = self._player:GetAttribute("SpawnPosition")
	self._character_handler:HandleCharacter(spawn_position)
	-- self._player:SetAttribute("SpawnPosition", nil)
	return
end
--******************************************--

----------------TOOL HANDLER------------------
function PlayerClass:UnequipAll(): nil
	self._tool_handler:UnequipAll()
	return
end

function PlayerClass:GetBasket(): types.BasketObject?
	return self._tool_handler:GetBasket()
end

function PlayerClass:EquipTool(tool_name: string): nil
	self._tool_handler:EquipTool(tool_name)
	return
end

function PlayerClass:UnequipTool(tool_name: string): nil
	self._tool_handler:UnequipTool(tool_name)
	return
end

function PlayerClass:AddTool(tool_name: string, tool_class: { [string]: any }, tool_data: types.ToolData)
	return self._tool_handler:AddTool(tool_name, tool_class, tool_data)
end

function PlayerClass:RemoveTool(tool_name: string, no_update: boolean?): nil
	self._tool_handler:RemoveTool(tool_name, no_update)
	return
end
--******************************************--

----------------EGG HANDLER------------------
function PlayerClass:AddEgg(egg_id: string): nil
	self._egg_handler:AddEgg(egg_id)
	return
end

function PlayerClass:GetEggs(): { string }
	return self._egg_handler:GetEggs()
end

function PlayerClass:PopEggs(amount: number): { string }?
	return self._egg_handler:PopEggs(amount)
end

function PlayerClass:StealEggs(amount: number): { string }?
	return self._egg_handler:StealEggs(amount)
end

function PlayerClass:ClearEggs(): nil
	self._egg_handler:ClearEggs()
	return
end
--******************************************--

function PlayerClass:RespawnTimer(): nil
	if not self.RespawnTimerObj then
		self.RespawnTimerObj = TimedFunction.new()
	end

	self.RespawnTimerObj:StartTimer(function()
		if self._player:GetAttribute("RespawnTimer") > 0 then
			self._player:SetAttribute("RespawnTimer", self._player:GetAttribute("RespawnTimer") - 1)
			self:RespawnTimer()
		else
			self.RespawnTimerObj:Destroy()
			self.RespawnTimerObj = nil
		end
	end)

	return
end

function PlayerClass:CleanRespawn(): nil
	if self.RespawnTimerObj then
		self.RespawnTimerObj:CancelTimer()
	end
	return
end

function PlayerClass:GetPlayer(): Player
	return self._player
end

function PlayerClass:ResetTools()
	self._tool_handler:ResetTools()
	self:InitialLoading()
end

function PlayerClass:DeathHandler()
	CollectionService:RemoveTag(self.Character, "Healable")
	self._player:SetAttribute("RespawnTimer", RESPAWN_TIMER)
	self:RespawnTimer()
	CollectionService:AddTag(self.Character, "Revivable")
	self.Core.Fire("PlayerDeath", self._player, self.Character)
	self._maid:DoCleaning()
	self:UnequipAll()
	self._character_handler:Ragdoll()
end

function PlayerClass:HandleCharacterAddition(): nil
	self._player.CharacterAdded:Connect(function(_)
		self._character_handler:DestroyRagdoll()

		self:CleanRespawn()
		self._player:SetAttribute("RespawnTimer", nil)
		self._maid.EffectObject = self.Core.EffectManager.Create("Player")
		self:HandleCharacter()
	end)

	return
end

function PlayerClass:InitialLoading(): nil
	self.Core.DataManager.SetGeneralValue(self._player, "SpaceAddition", 0)

	local equipped_table: {} = {}

	for item_id, item in self.Core.DataManager.GetPlayerData(self._player).Items do
		local item_data: {} = self.Core.ItemDataManager.GetItem(item_id)
		if not item_data then
			continue
		end

		if item.Equipped then
			equipped_table[item_id] = self.Core.ToolManagerServer.AddTool(self._player, item_id)
		end
	end
	self.Core.Utils.Net:RemoteEvent("BulkAddition"):FireClient(self._player, equipped_table)
	return
end

function PlayerClass:SpawnPlayer(spawn_position: CFrame?): nil
	self._player:SetAttribute("SpawnPosition", spawn_position)
	self._player:LoadCharacter()
	return
end

function PlayerClass.new(player, Core): types.PlayerObject
	local self: types.PlayerObject = setmetatable({} :: types.PlayerObject, PlayerClass)

	self._player = player
	self.Core = Core

	if not TimedFunction then
		TimedFunction = require(self.Core.Classes:WaitForChild("TimedFunction"))
	end

	self._maid = Core.Utils.Maid.new()
	self._spawn_position = nil

	self._maid.EffectObject = self.Core.EffectManager.Create("Player")

	self._tool_handler = ToolHandler.new(self)
	self._egg_handler = EggHandler.new(self)
	self._character_handler = CharacterHandler.new(self)

	self.Core.Utils.Net:RemoteEvent(`{self._player.UserId}_tool`)
	self.Core.Utils.Net:RemoteEvent(`{self._player.UserId}_hat`)

	self._player:LoadCharacter()
	self:HandleCharacter()
	self:HandleCharacterAddition()

	return self
end

function PlayerClass:Destroy(): nil
	self._maid:DoCleaning()
	self._tool_handler:Destroy()
	self._egg_handler:Destroy()
	self._character_handler:Destroy()
	self._maid = nil
	self._player = nil
	return
end

return PlayerClass
