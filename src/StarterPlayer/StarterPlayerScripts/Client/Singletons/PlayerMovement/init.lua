local PlayerMovement = {
	Name = "PlayerMovement",
}
--[[
	<description>
		This manager is responsible for handling the player movement.
	</description> 
	
	<API>		
		PlayerMovement.Sprint(status: boolean)  ---> nil
			-- Sprinting Functionality, icnrease/deacrease the player's walk speed 
			status : boolean ---> true if player is sprinting and false if player is NOT sprinting

		PlayerMovement.CancelSprint() ---> nil
			-- Stop sprinting and trigger stamina regeneration. 
			
		PlayerMovement.LockMovement(status: boolean, event_name: string?) ---> nil
			-- Lock player movement controls, resulting in player being locked in place. 
			status: boolean ---> true if one wants to lock player, false to unlock
			event_name: string ---> Provide a name for locking event, useful if one wants to overlap locking mechanics. 
									DEFAULT: "LockMovement"

		PlayerMovement.TiltStart() ---> nil
			-- Rotate the RootJoint of player based on Movement Velocity (higher priority) and Rotation Velocity 
			-- this rotation gives a "Tilting" effect. 

		PlayerMovement.TiltEnd() ---> nil 
			-- Stop the tilting effect and return RootJoint to its original CFrame.

		PlayerMovement.Knockback(direction: Vector3, velocity: number, duration: number) ---> nil
			-- Apply a velocity on player in specified direction for specified duraion 
			direction : Vector3 -- direction of velocity to apply on player 
			velocity : number -- the magnitude of the velocity to apply on player 
			duration : number -- duration for which to apply velocity on player

		PlayerMovement.ApplyImpulse(direction: Vector3) ---> nil
			-- Apply impulse on humanoid root part 
			direction : Vector3 -- the direction AND magnitude of impulse 
		
		PlayerMovement.Jump() ---> nil
			-- Make player jump if conditions permit

		PlayerMovement.IsOnSnow(): boolean
			-- Return TRUE if material player is on is in SNOW_MATERIALS, else return FALSE

		PlayerMovement.Overweight(space_taken: number, space_allowed: number) ---> nil
			-- apply or remove overweight effects based on space 
			space_taken: number -- the amount of space occupied by items in BACKPACK (not equipped)
			space_allowed: number -- the space limit, which, if passed, results in player being overweight 

		PlayerMovement.ActionHandler(action_name : string, input_state : Enum.UserInputState, _input_object : InputObject) ---> nil
			-- Route actions from BindAction
			action_name : string --> Name of action ("Sprint", etc)
			input_state : Enum.UserInputState --> User input state (Begin, End, etc)
			_input_object : InputObject ---> The InputObject...
		
		PlayerMovement.CreateStaminaObject() -- StaminaObject 
			-- Return a new Stamina class instance 

		PlayerMovement.InputManager() ---> nil
			-- Handle all the input and setup the BindActions
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

export type DirectionType = { x: number, y: number, z: number }

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StaminaClass = require(script:WaitForChild("Stamina"))

local DEFAULT_CHARACTER_MOVE_SPEED: number = 11
local SPRINT_SPEED: number = 23
local SPRINT_MULTIPLIER: number = SPRINT_SPEED / DEFAULT_CHARACTER_MOVE_SPEED
local SNOW_MULTIPLIER: number = 0.5

local SPEED_CHANGE_EVENT: string = "SpeedAction"
local SPEED_OVERWEIGHT_MULTIPLIER: number = 0.65

local CANCEL_JUMP_EVENT: string = "CancelJump"
local CANCEL_SPRINT_EVENT: string = "CancelSprint"

local KNOCKBACK_VELOCITY_MULTIPLIER: number = 100
local JUMP_STAMINA: number = 25

local TILT_TWEEN_INFO = TweenInfo.new(
	0.2,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)

local Core
local Maid
local MaidNonDupe
local RootJoint_C0_Original

local Sprint_Status: boolean = false
local Is_Moving: boolean = false
local Sprint_Disabled: boolean = false
local Jump_Disabled: boolean = false
local Double_Jump_Enable: boolean = false
local CurrentMaterial: Enum.Material? = nil
local LastWalkSpeedMultiplier: number = 1
local Sprint_Disable_Status: {} = {}
local Jump_Disable_Status: {} = {}
local Double_Jump_Enable_Status: {} = {}

local JUMP_LIMIT: number = 2
local DEFAULT_JUMP_POWER: number = 50
local JUMP_ADDITION_MULTIPLIER: number = 1
local Can_Double_Jump: boolean = false
local Jump_Count: number = 0
local SNOW_MATERIALS = {
	[Enum.Material.Snow] = true,
}
--*************************************************************************************************--

-- Sprinting Functionality, icnrease/deacrease the player's walk speed
--status : Boolean ---> true if player is sprinting and false if player is NOT sprinting
function PlayerMovement.Sprint(status: boolean): nil
	Sprint_Status = status
	local multiplier: number = status and SPRINT_MULTIPLIER or nil
	Core.Fire(SPEED_CHANGE_EVENT, "Sprint", multiplier)
	Core.Fire("Sprint", status)
	return
end

function PlayerMovement.CancelSprint(): nil
	PlayerMovement.Sprint(false)
	-- Maid.StaminaObject:RegenerateStamina()
	return
end

function PlayerMovement.LockMovement(status: boolean, event_name: string?): nil
	local maid_key: string = if event_name ~= nil then event_name else "LockMovement"
	if status then
		print("LOCKED!")
		Maid:GiveBindAction(maid_key)
		ContextActionService:BindAction(maid_key, function()
			return Enum.ContextActionResult.Sink
		end, false, unpack(Enum.PlayerActions:GetEnumItems()), unpack(Enum.UserInputType:GetEnumItems()))
	else
		ContextActionService:UnbindAction(maid_key)
	end
	return
end

function PlayerMovement.TiltStart(): nil
	Maid.TiltEvent = RunService.Heartbeat:Connect(function()
		if Core.RootJoint then
			local velocity: Vector3 = Core.HumanoidRootPart.Velocity
			local rotation_velocity: Vector3 = Core.HumanoidRootPart.AssemblyAngularVelocity

			local tilt_angle: number = 0

			if velocity.Magnitude > 2 then
				local direction: Vector3 = velocity.Unit
				tilt_angle = Core.HumanoidRootPart.CFrame.RightVector:Dot(direction) / 5
			elseif rotation_velocity.Magnitude > 0.5 then
				tilt_angle = math.clamp(rotation_velocity.Y / 5, -1 / 5, 1 / 5)
			end

			TweenService
				:Create(
					Core.RootJoint,
					TILT_TWEEN_INFO,
					{ C0 = RootJoint_C0_Original * CFrame.Angles(0, -tilt_angle, 0) }
				)
				:Play()
		end
	end)
	return
end

function PlayerMovement.TiltEnd(): nil
	Maid.TiltEvent = nil
	TweenService:Create(Core.RootJoint, TILT_TWEEN_INFO, { C0 = RootJoint_C0_Original })
	return
end

function PlayerMovement.Knockback(direction: Vector3, velocity: number, duration: number): nil
	if not velocity then
		velocity = KNOCKBACK_VELOCITY_MULTIPLIER
	end

	if not duration then
		duration = 0.5
	end

	direction = direction.Unit

	local hum_position: Vector3 = Core.Character.HumanoidRootPart.Position
	local face_dir: Vector3 = hum_position + direction * -10 -- Direction player will be rotated towards for animation

	Core.Character.HumanoidRootPart.CFrame = CFrame.new(hum_position, face_dir)

	Core.Fire("Knockback", true)
	Core.Humanoid.AutoRotate = false
	Core.Character.HumanoidRootPart.AssemblyLinearVelocity = direction * velocity -- add a linear velocity in Knockback direction

	Core.Promise.delay(duration):finally(function()
		Core.Fire("Knockback", false)
		Core.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0) -- remove the Knockback velocity
		Core.Humanoid.AutoRotate = true
	end)

	return
end

function PlayerMovement.ApplyImpulse(body_part_name: string, direction: Vector3): nil
	local body_part: Instance = Core.Character:FindFirstChild(body_part_name)
	if body_part then
		body_part:ApplyImpulse(direction) -- HumanoidRootPart
	end
	return
end

function PlayerMovement.Jump(): nil
	if Jump_Disabled then
		return
	end

	local double_jump_status: boolean = not Can_Double_Jump or Jump_Count >= JUMP_LIMIT or not Double_Jump_Enable

	if not Core.ActionStateManager:getState()["Grounded"] and double_jump_status then
		return
	end

	Can_Double_Jump = false
	Core.Humanoid.JumpPower = DEFAULT_JUMP_POWER + DEFAULT_JUMP_POWER * Jump_Count * JUMP_ADDITION_MULTIPLIER
	Jump_Count += 1
	Core.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	return
end

-- function PlayerMovement.Jump(): nil
-- 	if Jump_Disabled then
-- 		return
-- 	end

-- 	local current_state: {} = Core.ActionStateManager:getState()

-- 	if not current_state.Grounded then
-- 		return
-- 	end

-- 	if Maid.CooldownManager:CheckCooldown("Jump") then
-- 		return
-- 	end

-- 	if current_state.Stamina < JUMP_STAMINA then
-- 		return
-- 	end

-- 	Maid.StaminaObject:RemoveStamina(JUMP_STAMINA)

-- 	Core.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
-- 	return
-- end

-- function PlayerMovement.UpperTorsoVelocity()
-- 	-- TODO: Consider neck attachments
-- 	local headOffset = Core.Character.Torso.Size * Vector3.new(0, 0.5, 0)
-- 		+ Core.Character.Head.Size * Vector3.new(0, 0.5, 0)
-- 	local headPosition = Core.Character.Torso.CFrame:PointToWorldSpace(headOffset)

-- 	return Core.Character.Torso:GetVelocityAtPosition(headPosition)
-- end

function PlayerMovement.IsOnSnow(): boolean
	if SNOW_MATERIALS[CurrentMaterial] then
		return true
	end
	return false
end

function PlayerMovement.Overweight(space_taken: number, space_allowed: number): nil
	-- if space_taken > space_allowed then
	-- 	Core.Fire(SPEED_CHANGE_EVENT, "Overweight", SPEED_OVERWEIGHT_MULTIPLIER)
	-- 	Core.Fire(CANCEL_SPRINT_EVENT, nil, "Overweight", true)
	-- 	Core.Fire(CANCEL_JUMP_EVENT, nil, "Overweight", true)
	-- else
	-- 	Core.Fire(SPEED_CHANGE_EVENT, "Overweight", nil)
	-- 	Core.Fire(CANCEL_SPRINT_EVENT, nil, "Overweight", false)
	-- 	Core.Fire(CANCEL_JUMP_EVENT, nil, "Overweight", false)
	-- end
	return
end

function PlayerMovement.ActionHandler(
	action_name: string,
	input_state: Enum.UserInputState,
	_input_object: InputObject
): nil
	if input_state == Enum.UserInputState.Begin then
		if action_name == "Sprint" then
			if Sprint_Disabled then
				return
			end
			if Maid.CooldownManager:CheckCooldown("Sprint") then
				return
			end
			PlayerMovement.Sprint(true)
			-- Maid.StaminaObject:DrainStamina()
		elseif action_name == "Jump" then
			PlayerMovement.Jump()
		end
	else
		if action_name == "Sprint" and Sprint_Status then
			PlayerMovement.CancelSprint()
		end
	end

	return
end

function PlayerMovement.CreateStaminaObject()
	return StaminaClass.new()
end

function PlayerMovement.InputManager(): nil
	Maid:GiveBindAction("Sprint")
	ContextActionService:BindAction("Sprint", PlayerMovement.ActionHandler, true, Enum.KeyCode.LeftShift)

	Maid:GiveBindAction("Jump")
	ContextActionService:BindAction("Jump", PlayerMovement.ActionHandler, true, Enum.KeyCode.Space)

	Maid:GiveTask(Core.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if Core.Humanoid.MoveDirection.Magnitude > 0 and not Is_Moving then
			Is_Moving = true
			Core.Fire("Movement", true) -- fire event letting know that player is moving
		elseif Core.Humanoid.MoveDirection.Magnitude <= 0 and Is_Moving then
			Is_Moving = false
			Core.Fire("Movement", false) -- fire event letting know that no longer moving
		end
	end))

	Maid:GiveTask(Core.Subscribe("ResourceTrigger", function(status: boolean): nil
		PlayerMovement.LockMovement(status, "ResourceTrigger")
		return
	end))

	Maid:GiveTask(Core.Player:GetAttributeChangedSignal("Stun"):Connect(function(): nil
		local status: boolean = if Core.Player:GetAttribute("Stun") then true else false
		Core.Player:SetAttribute("CameraPositionLock", status)
		PlayerMovement.LockMovement(status, "Stun")
		Core.Fire("Stun", status)

		return
	end))

	return
end

function PlayerMovement.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("StaminaDrained", function()
		PlayerMovement.CancelSprint()
	end))

	Maid:GiveTask(
		Core.Subscribe("CancelSprint", function(cooldown: number?, disable_source: string?, disable_status: boolean?)
			if cooldown then
				Maid.CooldownManager:OneTimeCooldown("Sprint", cooldown)
			end
			PlayerMovement.CancelSprint()

			if disable_status ~= nil then
				Sprint_Disable_Status[disable_source] = disable_status
				local disable: boolean = false

				for _, i in Sprint_Disable_Status do
					disable = i
					if disable then
						break
					end
				end

				Sprint_Disabled = disable
			end
		end)
	)

	-- Maid:GiveTask(Core.Subscribe("Space", function(space_taken: number, space_allowed: number): nil
	-- 	-- PlayerMovement.Overweight(space_taken, space_allowed)
	-- 	return
	-- end))

	Maid:GiveTask(
		Core.Subscribe("CancelJump", function(cooldown: number?, disable_source: string?, disable_status: boolean?)
			if cooldown then
				Maid.CooldownManager:OneTimeCooldown("Jump", cooldown)
			end

			if disable_status ~= nil then
				Jump_Disable_Status[disable_source] = disable_status
				local disable: boolean = false

				for _, i in Jump_Disable_Status do
					disable = i
					if disable then
						break
					end
				end

				Jump_Disabled = disable
			end
		end)
	)

	Maid:GiveTask(Core.Subscribe("EnableDoubleJump", function(enable_source: string?, enable_status: boolean?)
		if enable_status ~= nil then
			Double_Jump_Enable_Status[enable_source] = enable_status
			local enable: boolean = false

			for _, i in Double_Jump_Enable_Status do
				enable = i
				if enable then
					break
				end
			end

			Double_Jump_Enable = enable
		end
	end))

	Maid:GiveTask(Core.ActionStateManager.changed:connect(function(newState, _)
		if newState.WalkSpeedMultiplier ~= LastWalkSpeedMultiplier then
			Core.Humanoid.WalkSpeed = DEFAULT_CHARACTER_MOVE_SPEED * newState.WalkSpeedMultiplier
			LastWalkSpeedMultiplier = newState.WalkSpeedMultiplier
		end
	end))

	Maid:GiveTask(Core.Humanoid.StateChanged:Connect(function(_oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			Core.Fire("Grounded", false)
			Can_Double_Jump = false
		elseif newState == Enum.HumanoidStateType.Freefall then
			Can_Double_Jump = true
		elseif newState == Enum.HumanoidStateType.Landed then
			Core.Fire("Grounded", true)
			Can_Double_Jump = false
			Jump_Count = 0
		end
	end))

	Maid:GiveTask(
		Core.Utils.Net
			:RemoteEvent("Knockback").OnClientEvent
			:Connect(function(direction: Vector3, velocity: number, duration: number)
				PlayerMovement.Knockback(direction, velocity, duration)
			end)
	)

	Maid:GiveTask(Core.Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		local new_material: Enum.Material = Core.Humanoid.FloorMaterial
		if CurrentMaterial ~= new_material then
			CurrentMaterial = new_material
			if SNOW_MATERIALS[new_material] then
				Core.Fire(SPEED_CHANGE_EVENT, "Snow", SNOW_MULTIPLIER)
				Core.Fire("Snow", true)
			else
				Core.Fire(SPEED_CHANGE_EVENT, "Snow", nil)
				Core.Fire("Snow", false)
			end
		end
	end))

	return
end

function PlayerMovement.ConstantEvents(): nil
	Core.Utils.Net
		:RemoteEvent("ApplyImpulse").OnClientEvent
		:Connect(function(body_part_name: string, direction: Vector3)
			print("IMPULSE: ", body_part_name)
			PlayerMovement.ApplyImpulse(body_part_name, direction)
		end)
	return
end

function PlayerMovement.Start(): nil
	-- Maid.DeathCam = nil
	while not Core.Character and not Core.Humanoid do
		RunService.Heartbeat:Wait()
	end
	CurrentMaterial = Core.Humanoid.FloorMaterial
	Maid.StaminaObject = StaminaClass.new()
	RootJoint_C0_Original = Core.RootJoint.C0
	Maid.CooldownManager = Core.CooldownClass.new({ { "Sprint", 0.1 }, { "Jump", 0.5 } })
	Core.Fire("Stamina", StaminaClass.GetMaxStamina())
	PlayerMovement.InputManager()
	PlayerMovement.TiltStart()
	PlayerMovement.EventHandler()
	PlayerMovement.LockMovement(false, "Death")

	return
end

function PlayerMovement.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	MaidNonDupe = Core.Utils.Maid.new()

	PlayerMovement.ConstantEvents()
	return
end

function PlayerMovement.Reset(): nil
	Maid:DoCleaning()
	PlayerMovement.LockMovement(true, "Death")
	LastWalkSpeedMultiplier = 1

	-- local lastVelocity = PlayerMovement.UpperTorsoVelocity()
	-- Maid.DeathCam = RunService.Heartbeat:Connect(function()
	-- 	debug.profilebegin("ragdollcamerashake")

	-- 	local cameraCFrame = Core.Camera.CFrame

	-- 	local velocity = PlayerMovement.UpperTorsoVelocity()
	-- 	local dVelocity = velocity - lastVelocity
	-- 	if dVelocity.magnitude >= 0.1 then
	-- 		Core.CameraManager.Impulse(
	-- 			cameraCFrame:vectorToObjectSpace(-0.1 * cameraCFrame.lookVector:Cross(dVelocity)) * 7,
	-- 			3.35,
	-- 			30
	-- 		)
	-- 	end

	-- 	lastVelocity = velocity
	-- 	debug.profileend()
	-- end)

	return
end

return PlayerMovement
