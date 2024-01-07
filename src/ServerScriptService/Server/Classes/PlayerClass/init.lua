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

		PlayerObject:AddTool(tool_name: string, tool_object : Tool) ---> nil
			-- Add a tool object and unequip any tool on top of the toolstack if there if the max number of added tools is surpassed.
			tool_name : string -- Name of the tool being added
			tool_object :  {[string] : any} -- Instance of class for specified tool
			
		PlayerObject:RemoveTool(tool_name: string) ---> nil
			-- Remove a tool from player, destroy its resources.
			tool_name : string -- Name of the tool being removed
			
		PlayerObject:EquipTool(tool_name: string) ---> nil
			-- Equip the tool specified. Unequip previously equipped tool first. 
			tool_name : string -- Name of the tool being equipped
			
		PlayerObject:UnequipTool(tool_name : string, tool_object : Tool) ---> nil
			-- Unequip the tool specified
			tool_name : string -- Name of the tool being unequipped
			
		PlayerObject:UnequipAll() ---> nil
			-- Unequip any equipped tools
			
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

		PlayerObject:DepleteHunger() ---> nil
			-- Begin depleting hunger, or health if hunger is depleted. 

		PlayerObject:CancelHunger() ---> nil
			-- Cancel the hunger promise and stop hunger depletion. 

		PlayerObject:StartBleeding(duration: number?) ---> nil
			-- Deplete user health for a specified duration in intervals of 3 seconds 
			duration: number? -- Specified duration : DEFAULT is 15

		PlayerObject:CancelBleeding() ---> nil
			-- Cancel bleeding promise and stop effects. 

		PlayerObject:RespawnTimer(): nil
			-- Trigger the respawn timer 

		PlayerObject:CleanRespawn(): nil
			-- Cancel the respawn timer 

		PlayerObject:GetProjectile(projectile_id: string, raycast_params, ray_update_callback, ray_hit_callback, on_terminating_callback, on_pierced_callback): {}
			-- Return a projectile instance or create it if doesn't exit.
			raycast_params: RaycastParams? -- Raycast Parameters for projectile. Optional.
			ray_hit_callback -- On hit callback
			ray_update_callback -- On ray update callback. Optional.
			on_terminating_callback -- On ray terminating callback. Optional.
			on_pierced_callback -- On ray pierced callback. Optional.

		PlayerObject:GetPosition() ---> Vector3 
			-- Return the player's current position 

		PlayerObject:GetPosition() ---> CFrame 
			-- Return the player's current HRP CFrame 

		PlayerObject:SpawnPlayer() ---> nil 
			-- Load player's Character 
			
		PlayerObject:HandleCharacter() ---> nil
			-- Get the player's character and humanoid and listen for death to perform cleanup.
		
		PlayerObject:ResetTools() ---> nil
			-- Destroy the players current tool objects and re initialize them
			also recount space.
		
		PlayerObject:InitialLoading(): nil
			-- Add all items that are supposed to be equipped and calculate space taken. 

		PlayerObject:HandleCharacterAddition() ---> nil
			-- Listen for the addition of the player's character (such as after death) to 
			-- setup the neccessary connections. 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local TimedFunction = nil
local RagdollClass = require(script:WaitForChild("Ragdoll"))
local ProjectileManagerClass = require(script.Parent:WaitForChild("ProjectileManager"))
local CollectionService = game:GetService("CollectionService")
local EquippedToolGroupCache = {}

local X_VECTOR: Vector3 = Vector3.new(1, 0, 0)
local Y_VECTOR: Vector3 = Vector3.new(0, 1, 0)
local Z_VECTOR: Vector3 = Vector3.new(0, 0, 1)

local RESPAWN_TIMER: number = 10
local MAX_HUNGER: number = 100

local DEFAULT_BLEEDING_DURATION: number = 15
local BLEEDING_DAMAGE: number = 10
local BLEEDING_INTERVAL: number = 3

local HUNGER_DEPLETION: number = 10
local HUNGER_DAMAGE: number = 10

--*************************************************************************************************--

function PlayerClass:AttachObject(object: Instance, item_id: string, dont_clone: boolean?): nil
	local attach_data: {}? = self.Core.Utils.ItemDataManager.GetAttachmentPosition(item_id)
	if not attach_data then
		return
	end

	local accessory: Accessory = object

	if not dont_clone then
		accessory = self.Core.Utils.UtilityFunctions.ToAccessory(object:Clone())
	end

	local handle: Instance? = accessory:FindFirstChild("Handle")
	accessory.AccessoryType = attach_data.AccessoryType

	local attach_point: Attachment = Instance.new("Attachment")
	attach_point.Name = attach_data.AttachmentPoint
	attach_point.Parent = handle

	attach_point.Position = attach_data.OffsetPosition
	attach_point.Orientation = attach_data.OffsetRotation

	self.Core.Utils.UtilityFunctions.UnanchorObject(accessory)

	accessory.Parent = self.Character
end

function PlayerClass:HoldItem(object: Instance, attach_name: string): nil
	local attach_object: Instance? = self.Character:FindFirstChild(attach_name)

	if attach_object then
		self.Core.Utils.UtilityFunctions.ClearTempFolder(object)
		self.Core.Utils.UtilityFunctions.UnanchorObject(object)

		local size: Vector3 = object:GetExtentsSize()

		local attach_object_cframe: CFrame = attach_object.CFrame
		local attach_object_position: Vector3 = attach_object.Position
		local object_height_offset: CFrame = CFrame.new(Vector3.new(0, -attach_object.Size.Y / 2 - size.Y / 3, 0))

		local arm_point_cframe: CFrame = attach_object_cframe * object_height_offset
		local arm_point_position: Vector3 = arm_point_cframe.Position
		local arm_look_vector: Vector3 = (arm_point_position - attach_object_position).Unit

		local arm_x_cframe: CFrame = attach_object_cframe * CFrame.new(X_VECTOR)
		local arm_x_vector: Vector3 = (arm_x_cframe.Position - attach_object_position).Unit

		local forward_vector: Vector3 = arm_x_vector:Cross(arm_look_vector)

		local max_size: number = math.max(size.X, size.Y, size.Z)
		local max_axis: Vector3 = X_VECTOR

		if max_size == size.Y then
			max_axis = Y_VECTOR
		elseif max_size == size.Z then
			max_axis = Z_VECTOR
		end

		local object_dir: Vector3 = ((arm_point_cframe * CFrame.new(max_axis)).Position - arm_point_position).Unit
		local angle: math.number = -math.acos(math.clamp(object_dir:Dot(forward_vector), -1, 1))

		object:PivotTo(arm_point_cframe * CFrame.Angles(0, angle, 0))

		local weld: WeldConstraint = Instance.new("WeldConstraint")
		weld.Name = self._player.Name .. "Weld"
		weld.Part0 = attach_object
		weld.Part1 = object.PrimaryPart
		weld.Parent = object
	end
end

function PlayerClass:DetachObject(object: Instance): nil
	local weld_name: string = self._player.Name .. "Weld"
	local weld: Instance = object:FindFirstChild(weld_name)
	if weld then
		weld:Destroy()
	end
end

function PlayerClass:AddTool(tool_name: string, tool_class: { [string]: any }, tool_data): nil
	if self._tool_maid[tool_name] then
		self:RemoveTool(tool_name, true)
	end

	local equip_group = tool_data.EquipGroup
	if equip_group and EquippedToolGroupCache[equip_group] then
		self:RemoveTool(EquippedToolGroupCache[equip_group])
		EquippedToolGroupCache[equip_group] = nil
	end

	if #self._equip_stack >= self._MAX_EQUIP then
		self:RemoveTool(self._equip_stack[#self._equip_stack])
		self._equip_stack[#self._equip_stack] = nil
	end

	local tool_object: {}? = nil
	if tool_class then
		tool_object = tool_class.new(self._player, self, tool_data) -- Create a new instance of the tool
	end

	self._tool_maid[tool_name] = tool_object

	table.insert(self._equip_stack, tool_name)

	if equip_group then
		EquippedToolGroupCache[equip_group] = tool_name
	end

	local item_id: string = self.Core.ItemDataManager.NameToId(tool_name)
	if item_id then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. item_id .. "/Equipped", true)
	elseif tool_object then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. tool_object:GetId() .. "/Equipped", true)
	end

	return tool_object
end

function PlayerClass:AddEgg()
	print("ADDING EGG!")
	if self.EquippedTool and self.EquippedTool.AddEgg then
		self.EquippedTool:AddEgg()
	end
end

function PlayerClass:GetEggs()
	print("GETTING EGG!")
	local eggs = {}
	if self.EquippedTool and self.EquippedTool.GetEggs then
		eggs = self.EquippedTool:GetEggs()
	end
	return eggs
end

function PlayerClass:ClearEggs()
	print("CLEARING EGG!")
	if self.EquippedTool and self.EquippedTool.ClearEggs then
		self.EquippedTool:ClearEggs()
	end
	return
end

function PlayerClass:RemoveTool(tool_name: string, no_update: boolean?): nil
	if self.EquippedTool == self._tool_maid[tool_name] then
		self.EquippedTool = nil
	end

	self._tool_maid[tool_name] = nil

	for index: number, name: string in self._equip_stack do
		if name == tool_name then
			table.remove(self._equip_stack, index)
			break
		end
	end

	if no_update then
		return
	end

	local item_id: string = self.Core.ItemDataManager.NameToId(tool_name)
	if item_id then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. item_id .. "/Equipped", false)
	elseif self._tool_maid[tool_name] then
		self.Core.DataManager.UpdateItem(
			self._player,
			"Items/" .. self._tool_maid[tool_name]:GetId() .. "/Equipped",
			false
		)
	end

	return
end

function PlayerClass:EquipTool(tool_name: string): nil
	if self.EquippedTool and self.EquippedTool.Unequip then
		self.Humanoid:UnequipTools()
		self.EquippedTool:Unequip()
	end

	self.EquippedTool = self._tool_maid[tool_name]

	if self.EquippedTool and self.EquippedTool.Equip then
		local tool_obj: Instance = self.EquippedTool:GetToolObject()
		self.Core.Utils.UtilityFunctions.ClearTempFolder(tool_obj)
		self.Humanoid:EquipTool(tool_obj)
		local tool: Instance = self.EquippedTool:Equip()

		local Motor: Motor6D = Instance.new("Motor6D")
		Motor.Parent = self.Character["Right Arm"]

		local grip: string = self.Character["Right Arm"]:WaitForChild("RightGrip")
		Motor.Enabled = false
		Motor.C0 = grip.C0
		Motor.C1 = grip.C1
		Motor.Part0 = grip.Part0
		Motor.Part1 = grip.Part1
		Motor.Name = grip.Name
		grip.Enabled = false
		Motor.Enabled = true

		grip:Destroy()
	end
	return
end

function PlayerClass:UnequipTool(tool_name: string, tool_object: Tool): nil
	if self.EquippedTool and self.EquippedTool.IsEmpty then
		if not self.EquippedTool:IsEmpty() then
			print("BASKET NOT EMPTY!")
			return false
		end
	end

	self.Humanoid:UnequipTools()

	if self.EquippedTool and self.EquippedTool.Unequip then
		self.EquippedTool:Unequip()
	end

	self.EquippedTool = nil
	return true
end

function PlayerClass:UnequipAll(): nil
	if self.EquippedTool and self.EquippedTool.Unequip then
		self.EquippedTool:Unequip()
	end

	self.EquippedTool = nil

	return
end

function PlayerClass:DoDamage(
	damage_amount: number,
	damage_message: string?,
	damage_part_name: string?,
	damage_impulse: Vector3
): nil
	if self.Humanoid.Health <= 0 then -- 0.1 then
		return
	end

	if self.Humanoid.Health - damage_amount <= 0 then
		if damage_impulse then
			self._ragdoll_impulse = damage_impulse
			local part: Instance? = self.Character:FindFirstChild(damage_part_name)
			print("TRY TO SET: ", damage_part_name)
			print(part)
			if part then
				print("SET: ", damage_part_name)

				self._ragdoll_body_part_name = damage_part_name
			end
		end
	end

	self.Humanoid:TakeDamage(damage_amount)
	CollectionService:AddTag(self.Character, "Healable")

	self._maid.EffectObject:Emit("Hit", self.HumanoidRootPart, 45, true)

	return
end

function PlayerClass:Heal(heal_amount: number, heal_message: string?): boolean
	if self.Humanoid.Health >= self.Humanoid.MaxHealth or self.Humanoid.Health <= 0 then
		return false
	end

	self.Humanoid.Health = math.clamp(self.Humanoid.Health + heal_amount, 0.1, self.Humanoid.MaxHealth)
	if self.Humanoid.Health >= self.Humanoid.MaxHealth then
		CollectionService:RemoveTag(self.Character, "Healable")
	end

	return true
end

function PlayerClass:Knockback(duration: number, direction: Vector3): nil
	self.Core.Utils.Net:RemoteEvent("Knockback"):FireClient(self._player, direction.Unit, duration)
	return
end

function PlayerClass:Stun(duration: number): nil
	self._player:SetAttribute("Stun", true)
	local stun_position: Vector3 = self.HumanoidRootPart.Position
	self._maid.StunConnection = self.Humanoid.Running:Connect(function()
		if (self.HumanoidRootPart.Position - stun_position).Magnitude > 3.5 then
			self.HumanoidRootPart.Position = stun_position
		end
	end)
	if self._stun_promise then
		self._stun_promise:cancel()
		self._stun_promise = nil
	end
	self._stun_promise = self.Core.Utils.Promise.delay(duration)

	self._stun_promise:andThen(function()
		self._maid.StunConnection = nil
		self._player:SetAttribute("Stun", false)
		self.HumanoidRootPart.Anchored = false
	end)
	return
end

function PlayerClass:IsStunned(): boolean
	local stun_status: boolean = if self._player:GetAttribute("Stun") then true else false
	return stun_status
end

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

function PlayerClass:GetProjectile(
	projectile_id: string,
	raycast_params,
	ray_update_callback,
	ray_hit_callback,
	on_terminating_callback,
	on_pierced_callback
)
	return self._projectile_manager:CreateProjectile(
		projectile_id,
		self._player,
		raycast_params,
		ray_update_callback,
		ray_hit_callback,
		on_terminating_callback,
		on_pierced_callback
	)
end

function PlayerClass:CleanRespawn(): nil
	if self.RespawnTimerObj then
		self.RespawnTimerObj:CancelTimer()
	end
	return
end

function PlayerClass:GetPosition(): Vector3
	return self.HumanoidRootPart.Position
end

function PlayerClass:GetCFrame(): CFrame
	return self.HumanoidRootPart.CFrame
end

function PlayerClass:HandleCharacter(): nil
	self.Character = self._player.Character or self._player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")
	self.Humanoid.BreakJointsOnDeath = false

	self._ragdoll_impulse = Vector3.new(
		self._random_ragdoll_x:NextNumber(-1, 1),
		0,
		self._random_ragdoll_z:NextNumber(-1, 1)
	).Unit * 100
	self._ragdoll_body_part_name = "HumanoidRootPart"
	local spawn_position: CFrame = self._player:GetAttribute("SpawnPosition")
	if spawn_position then
		task.defer(function()
			self.HumanoidRootPart.CFrame = spawn_position
			self._player:SetAttribute("SpawnPosition", nil)
		end)
	end

	for _, item: Instance in self.Character:GetDescendants() do
		if item:IsA("BasePart") then
			item.CollisionGroup = "Players"
			if item.Name == "HumanoidRootPart" then
				self.Character.PrimaryPart = item
			end
		end
	end

	self._maid.CharacterDescendantAddedEvent = self.Character.DescendantAdded:Connect(function(item)
		if item:IsA("BasePart") then
			item.CollisionGroup = "Players"
			if item.Name == "HumanoidRootPart" then
				self.Character.PrimaryPart = item
			end
		end
	end)

	-- self:DepleteHunger()
	-- task.spawn(function()
	-- 	while true do
	-- 		self._maid.DeathRagdoll = RagdollClass.new(self._player, self.Character)
	-- 		self._maid.DeathRagdoll:Ragdoll(
	-- 			Vector3.new(self._random_ragdoll_x:NextNumber(-1, 1), 0, self._random_ragdoll_z:NextNumber(-1, 1)).Unit
	-- 		)
	-- 		task.wait(3)
	-- 		self._maid.DeathRagdoll:Restore()
	-- 		task.wait(5)
	-- 	end
	-- end)
	-- self._maid.DeathEvent = self.Humanoid.Died:Connect(function()
	-- 	print("HUMANOID DIED SERVER EVENT!")
	-- 	CollectionService:RemoveTag(self.Character, "Healable")
	-- 	self._player:SetAttribute("RespawnTimer", RESPAWN_TIMER)
	-- 	self:RespawnTimer()
	-- 	CollectionService:AddTag(self.Character, "Revivable")
	-- 	self.Core.Fire("PlayerDeath", self._player, self.Character)
	-- 	self._maid:DoCleaning()
	-- 	self:UnequipAll()
	-- 	self._equip_stack = {}
	-- 	self:AddHunger(MAX_HUNGER)
	-- end)

	return
end

function PlayerClass:ResetTools()
	self._tool_maid:DoCleaning()
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
	self._equip_stack = {}
	-- self:AddHunger(MAX_HUNGER)
	self._maid.DeathRagdoll = RagdollClass.new(self._player, self.Character)
	self._maid.DeathRagdoll:Ragdoll(self._ragdoll_body_part_name, self._ragdoll_impulse)
end

function PlayerClass:HandleCharacterAddition(): nil
	self._player.CharacterAdded:Connect(function(_)
		self._maid.DeathRagdoll = nil
		self:CleanRespawn()
		self._player:SetAttribute("RespawnTimer", nil)
		self._maid.EffectObject = self.Core.EffectManager.Create("Player")
		self:HandleCharacter()
	end)

	return
end

function PlayerClass:InitialLoading(): nil
	self.Core.DataManager.SetGeneralValue(self._player, "SpaceAddition", 0)

	-- local space: number = 0
	local equipped_table: {} = {}

	for item_id, item in self.Core.DataManager.GetPlayerData(self._player).Items do
		local item_data: {} = self.Core.ItemDataManager.GetItem(item_id)
		if not item_data then
			continue
		end

		if item.Equipped then
			-- print("Old Space: ", space, " Item: ", item_id, " Amount:", item.Amount - 1, " Weight:", item_data.Weight)
			-- space += (item.Amount - 1) * item_data.Weight
			-- print("New Space: ", space)
			equipped_table[item_id] = self.Core.ToolManagerServer.AddTool(self._player, item_id)
			-- else
			-- 	print("Old Space: ", space, " Item: ", item_id, " Amount:", item.Amount, " Weight:", item_data.Weight)
			-- 	space += item.Amount * item_data.Weight
			-- 	print("New Space: ", space)
		end
	end
	self.Core.Utils.Net:RemoteEvent("BulkAddition"):FireClient(self._player, equipped_table)
	-- self.Core.DataManager.SetGeneralValue(self._player, "Space", space)
	return
end

function PlayerClass:SpawnPlayer(spawn_position: CFrame?): nil
	self._player:SetAttribute("SpawnPosition", spawn_position)
	self._player:LoadCharacter()
	return
end

function PlayerClass.new(player, Core): {}
	local self = setmetatable({}, PlayerClass)

	self._player_tools = {}
	self._player = player
	self.Core = Core

	if not TimedFunction then
		TimedFunction = require(self.Core.Classes.TimedFunction)
	end

	self._maid = Core.Utils.Maid.new()
	self._tool_maid = Core.Utils.Maid.new()
	self._spawn_position = nil
	self._MAX_EQUIP = 10
	self._equip_stack = {}
	self._attached_objects = {}
	self._maid.EffectObject = self.Core.EffectManager.Create("Player")
	self._projectile_manager = ProjectileManagerClass.new()
	self._random_ragdoll_x = Random.new()
	self._random_ragdoll_z = Random.new()

	self.Core.Utils.Net:RemoteEvent(`{self._player.UserId}_tool`)
	self.Core.Utils.Net:RemoteEvent(`{self._player.UserId}_hat`)

	self._player:LoadCharacter()
	self:HandleCharacter()
	self:HandleCharacterAddition()

	return self
end

function PlayerClass:Destroy(): nil
	self._maid:DoCleaning()
	self._tool_maid:DoCleaning()
	self._tool_maid = nil
	self._maid = nil
	self._player = nil
	return
end

return PlayerClass
