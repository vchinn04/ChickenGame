local StandardMusket = {}
StandardMusket.__index = StandardMusket
--[[
	<description>
		This class provides the functionalities for the standard 
		musket. It has both melee and ranged functionalities. If 
		specified, the musket can also accept a bayonet which will let 
		the melee attacks do damage (default results in "shoving").
	</description> 
	
	<API>
		StandardMusketObject:GetId(): string
			-- Returns id of tool assigned to instance

		StandardMusketObject:MeleeSwing(): boolean?
			-- Perform a shove or a damaging swing if a bayonet is attached.

		StandardMusketObject:Attack() ---> nil 
			-- Perform attack and if it goes through increment attack number 

		StandardMusketObject:Ranged() ---> nil
			-- Fire a musket shot if it is loaded. 

		StandardMusketObject:Reload() ---> nil
			-- Attempt to reload musket if neccessary ammunition is present. Will
			work unless no ammunition or musket is FULLY loaded. Takes the duration of 
			the animation given.

		StandardMusketObject:Block(status) ---> nil 
			-- Block (true) or unblock (false) depending on status 
			status: boolean -- true to block and false to unblock 

		StandardMusketObject:Present() ---> nil 
			-- Perform Present action
			
		StandardMusketObject:Deflect() ---> nil 
			-- Reverse current swing animation, OR play the last swing in reverse to create a 
			   "deflection" effect. 

		StandardMusketObject:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		StandardMusketObject:Unequip() --> void
			-- Tares down connections such as input, etc
			
		StandardMusketObject:Destroy() --> void
			-- Tares down all connections and destroys components used (E.g. Melee)

		StandardMusket.new(tool_obj: Tool, tool_data: { [string]: any }) ---> StandardMusketObject
			-- tool_obj: Tool ---> Tool to which isntance is attached to 
			tool_data: { [string]: any } -- Tool data entry 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local ContextActionService = game:GetService("ContextActionService")

export type SwordType = {
	UserInput: () -> nil,
	Equip: () -> nil,
	Unequip: () -> nil,
	Destroy: () -> nil,
}

local BASE_TOOL_PATH: string = "Tools/BaseTool"
local MELEE_COMPONENT_PATH: string = "Tools/Melee"
local BAYONET_COMPONENT_PATH: string = "Tools/Bayonet"

local MUSKET_STATES: {} = {
	Rest = 1,
	Reloading = 2,
	Presenting = 3,
	Shoulder = 4,
}

local STANDARD_FIRE_REMOTE_EVENT: string = "StandardFire"
local CANCEL_SPRINT_EVENT: string = "CancelSprint"
local CANCEL_JUMP_EVENT: string = "CancelJump"

local SWING_DEBOUNCE_NAME: string = "Swing_Debounce"
local ATTACK_PREFIX: string = "Hit"
local SHIFT_LOCK_EVENT: string = "CameraLock"
local RELOAD_REMOTE_EVENT: string = "Reload"
local PRESENT_EVENT: string = "TakeAim"
local DEFAULT_PRESENT_FOV: number = 45
local SHOOT_EVENT: string = "ThrowSuccess"

local BLOCK_SERVER_EVENT: string = "Block"
local BLOCKING_STATE: string = "Blocking"

local DEFAULT_SPRINT_COOLDOWN: number = 3
local DEFAULT_PARRY_STAMINA_REQ: number = 60
local DEFAULT_ATTACK_COUNT: number = 3
local DEFAULT_SWING_STAMINA_REQ: number = 45
local DEFAULT_SWING_DEBOUNCE: number = 0.65
local DEFAULT_SWING_DURATION: number = 0.65
local DEFAULT_AMMUNITION_ID: string = "Flintlock"

local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(2.5, 0.25, 0)

local SPEED_CHANGE_EVENT: string = "SpeedAction"
local SPEED_PRESENT_MULTIPLIER: number = 0.5
local SPEED_RELOAD_MULTIPLIER: number = 0.5

--*************************************************************************************************--

function StandardMusket:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardMusket:MeleeSwing(): boolean?
	if self._core_maid.CooldownManager:CheckCooldown(SWING_DEBOUNCE_NAME) then
		return
	end

	local current_stamina: number = self.Core.ActionStateManager:getState().Stamina
	local bayonet_attached: boolean = self._core_maid._bayonet:IsAttached()
	local attack_number: number = bayonet_attached and self._bayonet_attack_number or self._attack_number
	local attack_list: {}? = bayonet_attached and self._tool_data.BayonetAttacks or self._tool_data.StandardAttacks
	local stamina_required: number = self._standard_attack_stamina

	if attack_list and attack_list[attack_number].Stamina then
		stamina_required = attack_list[attack_number].Stamina
	end

	if current_stamina < stamina_required then
		return
	end

	local anim_name: string = if attack_list then attack_list[attack_number].Name else ATTACK_PREFIX .. attack_number
	self._last_anim_name = anim_name

	self._swing_anim, _ = self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData[anim_name], nil, false)

	self._core_maid.StaminaObject:RemoveStamina(stamina_required)

	self.Core.Fire(CANCEL_SPRINT_EVENT, self._sprint_cooldown)

	if self._core_maid._clone_swing_sound then
		self._core_maid.SoundObject:Play(self._core_maid._clone_swing_sound)
	end

	if self._swing_trail then
		self._swing_trail.Enabled = true
	end

	if self._swing_anim then
		self._connection_maid.SwingCompletionEvent = self._swing_anim.Stopped:Connect(function()
			self._connection_maid.SwingCompletionEvent = nil
			self._swing_anim = nil
			if self._swing_trail then
				self._swing_trail.Enabled = false
			end
		end)
	end

	if bayonet_attached then
		self._core_maid._bayonet:Attack()
		self._bayonet_attack_number += 1
		if self._bayonet_attack_number > self._bayonet_attack_count then
			self._bayonet_attack_number = 1
		end
	else
		self._core_maid.MeleeManager:Attack()
		self._attack_number += 1
		if self._attack_number > self._attack_count then
			self._attack_number = 1
		end
	end

	return true
end

function StandardMusket:Attack(): nil
	if self._in_melee_mode then
		self:MeleeSwing()
		return
	end

	if self._current_state:get() == MUSKET_STATES.Presenting then
		self:Ranged()
	end

	return
end

function StandardMusket:Ranged(): nil
	if not self._item_data_entry.BulletCount then
		return
	end

	if self._item_data_entry.BulletCount <= 0 then
		return
	end

	self.Core.Fire(SHOOT_EVENT)

	self.Core.Utils.Net
		:RemoteEvent(`{self.Core.Player.UserId}_tool`)
		:FireServer(STANDARD_FIRE_REMOTE_EVENT, { Direction = self.Core.CameraManager.GetLookVector() })

	return
end

function StandardMusket:Block(status: boolean): nil
	self._tool_state:dispatch({ type = BLOCKING_STATE, Blocking = status })
	self._core_maid.MeleeManager:Block(status)

	if status then
		self._core_maid.StaminaObject:DrainStamina()
		self.Core.Fire(CANCEL_SPRINT_EVENT)
	else
		self._core_maid.StaminaObject:RegenerateStamina()
	end

	return
end

function StandardMusket:Reload(): nil
	if not self._tool_data.AnimationData.Reload then
		warn("There must be a reload animation to reload!")
		return
	end

	if self._current_state:get() == MUSKET_STATES.Reloading then
		return
	end

	if self._item_data_entry.BulletCount and self._item_data_entry.BulletCount >= self._tool_data.MaxBullets then
		return
	end

	if not self._bullet_data_entry then
		local bullet_id: string = self._tool_data.AmmoType

		if not bullet_id then
			bullet_id = DEFAULT_AMMUNITION_ID
		end

		self._bullet_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. bullet_id)
	end

	if not self._bullet_data_entry or self._bullet_data_entry.Amount <= 0 then
		return
	end

	if self._reload_promise then
		self._reload_promise:cancel()
		self._reload_promise = nil
	end

	self._current_state:set(MUSKET_STATES.Reloading)

	self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(RELOAD_REMOTE_EVENT, false)

	_, self._reload_promise = self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Reload, nil, true)
	self._reload_promise:andThen(function()
		self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(RELOAD_REMOTE_EVENT, true)
		self._current_state:set(MUSKET_STATES.Rest)
	end)

	return
end

function StandardMusket:Deflect(): nil
	if self._swing_anim then
		self._core_maid.Animator:SetSpeed(self._swing_anim, -1)
		return
	end
	if self._last_anim_name then
		self._core_maid.Animator:PlayReverse(self._tool_data.AnimationData[self._last_anim_name])
	end
	return
end

function StandardMusket:UserInput(): nil
	self._connection_maid:GiveBindAction("Attack")
	ContextActionService:BindAction(
		"Attack",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Cancel then
				return Enum.ContextActionResult.Pass
			end

			if self.Core.ActionStateManager:getState().MovementAbility then
				return Enum.ContextActionResult.Pass
			end

			if self._tool_state:getState().Blocking then
				return Enum.ContextActionResult.Pass
			end

			if input_state == Enum.UserInputState.Begin then
				self:Attack()
			end

			return
		end,
		true,
		Enum.UserInputType.MouseButton1
	)

	self._connection_maid:GiveBindAction("Present")
	ContextActionService:BindAction(
		"Present",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Cancel then
				return Enum.ContextActionResult.Pass
			end

			if self._current_state:get() == MUSKET_STATES.Reloading then
				return Enum.ContextActionResult.Pass
			end

			local input_began = input_state == Enum.UserInputState.Begin

			self.Core.Fire(PRESENT_EVENT, input_began, self._present_fov)
			self._current_state:set(input_began and MUSKET_STATES.Presenting or MUSKET_STATES.Rest)

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.UserInputType.MouseButton2
	)

	self._connection_maid:GiveBindAction("Reload")
	ContextActionService:BindAction(
		"Reload",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Begin then
				self:Reload()
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.R
	)

	self._connection_maid:GiveBindAction("ShoulderArms")
	ContextActionService:BindAction(
		"ShoulderArms",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Begin then
				local current_state: number = self._current_state:get()

				if current_state == MUSKET_STATES.Reloading or current_state == MUSKET_STATES.Presenting then
					return Enum.ContextActionResult.Pass
				end

				self._current_state:set(
					current_state == MUSKET_STATES.Shoulder and MUSKET_STATES.Rest or MUSKET_STATES.Shoulder
				)
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.T
	)

	self._connection_maid:GiveTask(self.Core.Subscribe("StaminaDrained", function()
		self:Block(false)
		return
	end))

	self._connection_maid:GiveBindAction("ModeSwitch")
	ContextActionService:BindAction(
		"ModeSwitch",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Begin then
				self._in_melee_mode = not self._in_melee_mode
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.Q
	)

	self._connection_maid:GiveBindAction("AttachBayonet")
	ContextActionService:BindAction(
		"AttachBayonet",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Begin then
				self._core_maid._bayonet:Attach()
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.K
	)

	self._connection_maid:GiveTask(self.Core.Subscribe("Parry", function()
		self:Deflect()
		return
	end))

	self._connection_maid:GiveTask(self.Core.Subscribe("Block", function()
		self:Deflect()
		return
	end))

	self._connection_maid:GiveTask(self._state_observer:onChange(function()
		local current_state: number = self._current_state:get()

		if current_state == MUSKET_STATES.Presenting then
			self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Present)
			self.Core.Fire(SPEED_CHANGE_EVENT, "Present", SPEED_PRESENT_MULTIPLIER)
			self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Musket", true)
			self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Musket", true)
		elseif current_state == MUSKET_STATES.Reloading then
			self.Core.Fire(SPEED_CHANGE_EVENT, "Reload", SPEED_RELOAD_MULTIPLIER)
			self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Musket", true)
			self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Musket", true)
		else
			self.Core.Fire(SPEED_CHANGE_EVENT, "Reload", nil)
			self.Core.Fire(SPEED_CHANGE_EVENT, "Present", nil)
			self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Musket", false)
			self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Musket", false)
		end

		if current_state == MUSKET_STATES.Shoulder then
			self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.ShoulderArms)
			self._core_maid.Animator:StopAnimation(self._tool_data.AnimationData.Idle)
		elseif current_state ~= MUSKET_STATES.Presenting then
			self.Core.Fire(PRESENT_EVENT, false, self._present_fov)
			self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Idle)
			self._core_maid.Animator:StopAnimation(self._tool_data.AnimationData.Present)
			self._core_maid.Animator:StopAnimation(self._tool_data.AnimationData.ShoulderArms)
		end
	end))

	return
end

function StandardMusket:Equip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, true, SHIFTLOCK_OFFSET)

	self._core_maid._base_tool:Equip()
	self._core_maid._bayonet:Equip()
	self._core_maid.MeleeManager:Start()
	self:UserInput()
	return
end

function StandardMusket:Unequip(): nil
	self._in_melee_mode = false
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	self._current_state:set(MUSKET_STATES.Rest)

	if self._reload_promise then
		self._reload_promise:cancel()
		self._reload_promise = nil
	end

	self._core_maid._base_tool:Unequip()

	self._connection_maid:DoCleaning()
	self._core_maid.Animator:DoCleaning()

	self._core_maid.MeleeManager:Stop()
	self._core_maid._bayonet:Unequip()

	self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(BLOCK_SERVER_EVENT, false)

	self._core_maid.StaminaObject:Clear()

	if self._swing_trail then
		self._swing_trail.Enabled = false
	end

	return
end

function StandardMusket:Destroy(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	self._current_state:set(MUSKET_STATES.Rest)
	if self._swing_trail then
		self._swing_trail.Enabled = false
	end

	if self._reload_promise then
		self._reload_promise:cancel()
		self._reload_promise = nil
	end

	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(BLOCK_SERVER_EVENT, false)

	self._current_state = nil

	self._swing_trail = nil
	self._connection_maid = nil
	self._core_maid = nil
	self = nil

	return
end

--[[
	<description>
		Sets up the user input connections such as swinging.
	</description> 
	
	<parameter name="tool_obj">
		Type: Tool
		Description: Tool instance player is equipping 
	</parameter 
	
	<parameter name="tool_data">
		Type: table
		Description: Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</parameter 	
--]]
function StandardMusket.new(tool_obj: Tool, tool_data: { [string]: any }): SwordType
	local self = setmetatable({}, StandardMusket)

	local swing_debounce: number = if tool_data.SwingDebounce then tool_data.SwingDebounce else DEFAULT_SWING_DEBOUNCE
	local swing_duration: number = if tool_data.SwingDuration then tool_data.SwingDuration else DEFAULT_SWING_DURATION

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	local bullet_id: string = self._tool_data.AmmoType
	if not bullet_id then
		bullet_id = DEFAULT_AMMUNITION_ID
	end

	self._item_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. tool_data.Id)
	self._bullet_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. bullet_id)

	self._in_melee_mode = false
	self._attack_number = 1
	self._bayonet_attack_number = 1
	self._attack_count = if tool_data.StandardAttacks then #tool_data.StandardAttacks else DEFAULT_ATTACK_COUNT
	self._bayonet_attack_count = if tool_data.BayonetAttacks then #tool_data.BayonetAttacks else DEFAULT_ATTACK_COUNT

	self._present_fov = if tool_data.PresentFOV then tool_data.PresentFOV else DEFAULT_PRESENT_FOV

	self._standard_attack_stamina = if tool_data.StandardStamina
		then tool_data.StandardStamina
		else DEFAULT_SWING_STAMINA_REQ

	self._sprint_cooldown = if tool_data.SprintCooldown then tool_data.SprintCooldown else DEFAULT_SPRINT_COOLDOWN
	self._parry_stamina_req = if tool_data.ParryStaminaReq then tool_data.ParryStaminaReq else DEFAULT_PARRY_STAMINA_REQ

	self._core_maid.CooldownManager = self.Core.CooldownClass.new({ { SWING_DEBOUNCE_NAME, swing_debounce } })
	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid.StaminaObject = self.Core.PlayerMovement.CreateStaminaObject()

	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)
	self._core_maid._bayonet =
		self.Core.Components[BAYONET_COMPONENT_PATH].new(tool_obj, tool_data, "Bayonet", self._core_maid.Animator)
	self._core_maid.MeleeManager =
		self.Core.Components[MELEE_COMPONENT_PATH].new(tool_obj, tool_data, swing_duration, self._core_maid.Animator)

	self._current_state = self.Core.Fusion.Value(MUSKET_STATES.Rest)
	self._state_observer = self.Core.Fusion.Observer(self._current_state)
	self._tool_state = self.Core.Utils.Rodux.Store.new(
		function(old_state: { [string]: any }, action: { type: string, [string]: any })
			old_state[action.type] = action[action.type]
			return old_state
		end,
		{
			Attacking = false,
			Blocking = false,
		}
	)

	if self._tool.Handle and self._tool.Handle:FindFirstChild("SwingTrail") then
		self._swing_trail = self._tool.Handle:FindFirstChild("SwingTrail")
	end

	if self._tool_data.SoundData then
		self._core_maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Client.Swing then
			self._core_maid._clone_swing_sound =
				self._core_maid.SoundObject:CloneSound(self._tool_data.SoundData.Client.Swing.Name, self._tool)
		end
	end
	return self
end

return StandardMusket
