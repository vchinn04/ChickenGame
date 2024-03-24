local CharacterHandler = {}
CharacterHandler.__index = CharacterHandler
--[[
	<description>
		This component handles character related functionalities for the player.
	</description> 
	
	<API>
		CharacterHandlerObject:AttachObject(object: Instance, item_id: string, dont_clone: boolean?) ---> nil
			-- Attach object as accessory to character
			object: Instance -- object to attach 
			item_id: string -- id of object 
			dont_clone: boolean? -- True: will not clone

		CharacterHandlerObject:HoldItem(object: Instance, attach_name: string) ---> nil
			-- Weld object to specified object in player character. 
			object: Instance -- the object to weld. A well of name player.Name will be added to object 
			attach_name: string -- the name of object in player to attach to 

	  	CharacterHandlerObject:DetachObject(object: Instance) ---> nil
			-- Detach object from player, by destroying the weld of name `player.Name`
			object: Instance -- Object to detach 
			
		CharacterHandlerObject:DoDamage(damage_amount : number, damage_message : string?) ---> nil
			-- Do damage to the player's Humanoid, display damage_message if applicable
			damage_amount : number -- Amount to damage by 

		CharacterHandlerObject:Heal(heal_amount: number, heal_message: string?) ---> boolean
			-- Heal the player unless already max health 
			heal_amount : number -- amount to heal by 
			Return true if successful else False

		CharacterHandlerObject:Knockback(duration: number, direction: Vector3) ---> nil
			-- Call the Knockback remote and pass the direction and duration of the Knockback
			duration : number -- Duration of the knockback
			direction : Vector3 -- Direction of knockback

		CharacterHandlerObject:Stun(duration: number) ---> nil
			-- Stun the player. Lock player's position in place for specified duration. 
			duration: number -- for how long to stun player 

		CharacterHandlerObject:IsStunned() ---> boolean
			-- Return the "Stun" attribute value 

            Ragdoll(): nil
            DestroyRagdoll(): nil

        CharacterHandlerObject:GetPosition() ---> Vector3 
			-- Return the player's current position 

		CharacterHandlerObject:GetCFrame() ---> CFrame 
			-- Return the player's current HRP CFrame 

        CharacterHandlerObject:GetCharacter() ---> Model
            -- Return the player's character 
            
        CharacterHandlerObject:GetHumanoid() ---> Humanoid?
            -- Return the player's humanoid

		PlayerObject:HandleCharacter(spawn_position: CFrame?) ---> nil
			-- Get the player's character and humanoid and listen for death to perform cleanup.
            spawn_position: CFrame?  -- Optional Custom Spawn position 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local CollectionService = game:GetService("CollectionService")

local types = require(script.Parent.Parent.Parent.Parent.ServerTypes)
local RagdollClass = require(script.Parent.Ragdoll)

local X_VECTOR: Vector3 = Vector3.new(1, 0, 0)
local Y_VECTOR: Vector3 = Vector3.new(0, 1, 0)
local Z_VECTOR: Vector3 = Vector3.new(0, 0, 1)

--*************************************************************************************************--

function CharacterHandler:AttachObject(object: Instance, item_id: string, dont_clone: boolean?): nil
	local attach_data: { [any]: any }? = self.Core.Utils.ItemDataManager.GetAttachmentPosition(item_id)
	if not attach_data then
		return
	end

	local accessory: Accessory | Instance = object
	if not accessory:IsA("Accessory") then
		return
	end

	accessory = accessory :: Accessory

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
	return
end

function CharacterHandler:HoldItem(object: Model, attach_name: string): nil
	if not object.PrimaryPart then
		return
	end

	local attach_object: BasePart? = self.Character:FindFirstChild(attach_name)

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
		local angle: number = -math.acos(math.clamp(object_dir:Dot(forward_vector), -1, 1))

		object:PivotTo(arm_point_cframe * CFrame.Angles(0, angle, 0))

		local weld: WeldConstraint = Instance.new("WeldConstraint")
		weld.Name = self._player.Name .. "Weld"
		weld.Part0 = attach_object
		weld.Part1 = object.PrimaryPart
		weld.Parent = object
	end
	return
end

function CharacterHandler:DetachObject(object: Instance): nil
	local weld_name: string = self._player.Name .. "Weld"
	local weld: Instance? = object:FindFirstChild(weld_name)
	if weld then
		weld:Destroy()
	end
	return
end

function CharacterHandler:DoDamage(
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

function CharacterHandler:Heal(heal_amount: number, heal_message: string?): boolean
	if self.Humanoid.Health >= self.Humanoid.MaxHealth or self.Humanoid.Health <= 0 then
		return false
	end

	self.Humanoid.Health = math.clamp(self.Humanoid.Health + heal_amount, 0.1, self.Humanoid.MaxHealth)
	if self.Humanoid.Health >= self.Humanoid.MaxHealth then
		CollectionService:RemoveTag(self.Character, "Healable")
	end

	return true
end

function CharacterHandler:Knockback(duration: number, direction: Vector3, force: number?): nil
	self.Core.Utils.Net:RemoteEvent("Knockback"):FireClient(self._player, direction.Unit, force, duration)
	return
end

function CharacterHandler:Stun(duration: number): nil
	self._player:SetAttribute("Stun", true)
	local stun_position: Vector3 = self.HumanoidRootPart.Position
	-- self._maid.StunConnection = self.Humanoid.Running:Connect(function()
	-- 	if (self.HumanoidRootPart.Position - stun_position).Magnitude > 3.5 then
	-- 		self.HumanoidRootPart.Position = stun_position
	-- 	end
	-- end)
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

function CharacterHandler:IsStunned(): boolean
	local stun_status: boolean = if self._player:GetAttribute("Stun") then true else false
	return stun_status
end

function CharacterHandler:Ragdoll(): nil
	self._maid.DeathRagdoll = RagdollClass.new(self._player, self.Character)
	self._maid.DeathRagdoll:Ragdoll(self._ragdoll_body_part_name, self._ragdoll_impulse)
	return
end

function CharacterHandler:DestroyRagdoll(): nil
	self._maid.DeathRagdoll = nil
	return
end

function CharacterHandler:HandleCharacter(spawn_position: CFrame?): nil
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

	if spawn_position then
		task.defer(function()
			self.HumanoidRootPart.CFrame = spawn_position
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

	return
end

function CharacterHandler:GetPosition(): Vector3
	return self.HumanoidRootPart.Position
end

function CharacterHandler:GetCFrame(): CFrame
	return self.HumanoidRootPart.CFrame
end

function CharacterHandler:GetCharacter(): Model
	return self.Character
end

function CharacterHandler:GetHumanoid(): Humanoid?
	return self.Humanoid
end

function CharacterHandler:Destroy(): nil
	self._maid:DoCleaning()

	self.Core = nil
	self._maid = nil

	self._player_object = nil
	self._player = nil

	self.Character = nil
	self.HumanoidRootPart = nil
	self.Humanoid = nil

	return
end

function CharacterHandler.new(player_object): types.CharacterHandlerObject
	local self: types.CharacterHandlerObject = setmetatable({} :: types.CharacterHandlerObject, CharacterHandler)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._player_object = player_object
	self._player = player_object:GetPlayer()

	self._ragdoll_impulse = nil
	self._ragdoll_body_part_name = nil
	self._random_ragdoll_x = Random.new()
	self._random_ragdoll_z = Random.new()

	self._stun_promise = nil

	self.Character = nil
	self.HumanoidRootPart = nil
	self.Humanoid = nil

	return self
end

return CharacterHandler
