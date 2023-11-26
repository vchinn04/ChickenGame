local ThrowableMelee = {}
ThrowableMelee.__index = ThrowableMelee
--[[
	<description>
		This class provides the functionalities for the throwable 
		Melee type. The difference between it and Standard Melee is that 
		by pressing a key one can switch to ranged mode and throw the 
		weapon.
	</description> 
	
	<API>
		ThrowableMeleeObject:GetId(): string
			-- Returns id of tool assigned to instance

		ThrowableMeleeObject:StandardSwing() ---> boolean?
			-- Perform a standard swing and return true if swing goes through. 

		ThrowableMeleeObject:Attack() ---> nil 
			-- Perform attack and if it goes through increment attack number 

		ThrowableMeleeObject:Ranged(status: boolean) ---> nil
			-- Provides the charging and throwing functionality. If status it true, begin charging 
			and once the charge is complete after a period of type begin screen shake for overcharge, 
			status : boolean -- set to true to charge and set to false to throw (if charge is above a min threshold)

		ThrowableMelee:CancelCharge() ---> Cancel the charge and the overcharge promise. Set 
		current charge to 0. Reset the UI Charge indicator. 

		ThrowableMeleeObject:Block(status) ---> nil 
			-- Block (true) or unblock (false) depending on status 
			status: boolean -- true to block and false to unblock 

		ThrowableMeleeObject:Parry() ---> nil 
			-- Perform parry action if conditions are met (stamina, etc) 

		ThrowableMeleeObject:Deflect() ---> nil 
			-- Reverse current swing animation, OR play the last swing in reverse to create a 
			   "deflection" effect. 

		ThrowableMeleeObject:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		ThrowableMeleeObject:Unequip() --> void
			-- Tares down connections such as input, etc
			
		ThrowableMeleeObject:Destroy() --> void
			-- Tares down all connections and destroys components used (E.g. Melee)

		ThrowableMelee.new(tool_obj: Tool, tool_data: { [string]: any }) ---> ThrowableMeleeObject
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
local CHARGE_CLASS_PATH: string = "Misc/ChargeClass"

local CANCEL_SPRINT_EVENT: string = "CancelSprint"
local SWING_DEBOUNCE_NAME: string = "Swing_Debounce"
local ATTACK_PREFIX: string = "Hit"
local SHIFT_LOCK_EVENT: string = "CameraLock"

local PARRY_SERVER_EVENT: string = "Parry"

local BLOCKING_STATE: string = "Blocking"

local DEFAULT_SPRINT_COOLDOWN: number = 3
local DEFAULT_PARRY_STAMINA_REQ: number = 60
local DEFAULT_ATTACK_COUNT: number = 3
local DEFAULT_SWING_STAMINA_REQ: number = 45
local DEFAULT_SWING_DEBOUNCE: number = 0.65
local DEFAULT_SWING_DURATION: number = 0.65
local DEFAULT_CHARGE_DURATION: number = 3
local DEFAULT_STABILITY_DURATION: number = 3

local CHARGE_THRESHOLD: number = 100
local CHARGE_EVENT: string = "ThrowCharge"
local CHARGE_OVERLOAD_EVENT: string = "ChargeOverload"
local SHOOT_EVENT: string = "ThrowSuccess"
local LAUNCH_REMOTE_EVENT: string = "Throw"

local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(2.1, 0.25, 0)

--*************************************************************************************************--

function ThrowableMelee:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function ThrowableMelee:StandardSwing(): boolean?
	local current_stamina: number = self.Core.ActionStateManager:getState().Stamina

	if current_stamina < self._standard_attack_stamina then
		return
	end

	if self._core_maid.CooldownManager:CheckCooldown(SWING_DEBOUNCE_NAME) then
		return
	end

	self._core_maid.StaminaObject:RemoveStamina(self._standard_attack_stamina)

	local anim_name: string = ATTACK_PREFIX .. self._attack_number
	self._last_anim_name = anim_name
	self._swing_anim, _ = self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData[anim_name], nil, false)

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

	self._core_maid.MeleeManager:Attack()

	return true
end

function ThrowableMelee:Attack(): nil
	local success: boolean = self:StandardSwing()
	if success then
		self._attack_number += 1
		if self._attack_number > self._attack_count then
			self._attack_number = 1
		end
	end
	return
end

function ThrowableMelee:Ranged(status: boolean): nil
	if status then
		self.Core.Fire(CHARGE_EVENT, true, self._charge_duration)

		self._core_maid._charge_object:Charge(100, self._charge_duration, function(new_charge: number)
			self._core_maid._cursor_bar:Set(new_charge / CHARGE_THRESHOLD)
		end, function(_)
			self._charge_overload_promise = self.Core.Utils.Promise.delay(self._stability_duration):andThen(function()
				self.Core.Fire(CHARGE_OVERLOAD_EVENT, true)
			end)
		end)
	else
		local current_charge: number = self._core_maid._charge_object:GetCharge()

		self:CancelCharge()

		if current_charge >= 3 then
			self.Core.Fire(SHOOT_EVENT, self._tool_data.AnimationData.Throw)

			self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(
				LAUNCH_REMOTE_EVENT,
				{ Direction = self.Core.CameraManager.GetLookVector(), Charge = current_charge }
			)
		end
	end
	return
end

function ThrowableMelee:CancelCharge(): nil
	self._core_maid._charge_object:CancelCharge()
	self._core_maid._cursor_bar:Reset()
	self.Core.Fire(CHARGE_EVENT, false, self._charge_duration)

	if self._charge_overload_promise then
		self._charge_overload_promise:cancel()
		self._charge_overload_promise = nil
	end

	self.Core.Fire(CHARGE_OVERLOAD_EVENT, false)
	return
end

function ThrowableMelee:Block(status: boolean): nil
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

function ThrowableMelee:Parry(): nil
	local current_stamina: number = self.Core.ActionStateManager:getState().Stamina

	if current_stamina < self._parry_stamina_req then
		return
	end

	self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(PARRY_SERVER_EVENT)

	if self._tool_data.AnimationData.Parry then
		self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Parry)
	end

	self._core_maid.StaminaObject:RemoveStamina(self._parry_stamina_req)
	self.Core.Fire(CANCEL_SPRINT_EVENT, self._sprint_cooldown)

	return
end

function ThrowableMelee:Deflect(): nil
	if self._swing_anim then
		self._core_maid.Animator:SetSpeed(self._swing_anim, -1)
		return
	end
	if self._last_anim_name then
		self._core_maid.Animator:PlayReverse(self._tool_data.AnimationData[self._last_anim_name])
	end
	return
end

function ThrowableMelee:UserInput(): nil
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

			if self._in_aim_mode then
				self:Ranged(input_state == Enum.UserInputState.Begin)
				return Enum.ContextActionResult.Pass
			end

			if input_state == Enum.UserInputState.Begin then
				self:Attack()
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.UserInputType.MouseButton1
	)

	self._connection_maid:GiveBindAction("Block")
	ContextActionService:BindAction("Block", function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
		if input_state == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end

		if self.Core.ActionStateManager:getState().MovementAbility then
			return Enum.ContextActionResult.Pass
		end

		local input_began: boolean = input_state == Enum.UserInputState.Begin

		self:Block(input_began)

		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton2)

	self._connection_maid:GiveBindAction("Parry")
	ContextActionService:BindAction("Parry", function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
		if input_state == Enum.UserInputState.Begin then
			if self._core_maid.CooldownManager:CheckCooldown("Parry_Debounce") then
				return Enum.ContextActionResult.Pass
			end

			self:Parry()
		end

		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.E)

	self._connection_maid:GiveTask(self.Core.Subscribe("StaminaDrained", function()
		self:Block(false)
		return
	end))

	self._connection_maid:GiveTask(self.Core.Subscribe("Parry", function()
		self:Deflect()
		return
	end))

	self._connection_maid:GiveTask(self.Core.Subscribe("Block", function()
		self:Deflect()
		return
	end))

	self._connection_maid:GiveBindAction("ModeSwitch")
	ContextActionService:BindAction(
		"ModeSwitch",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if input_state == Enum.UserInputState.Begin then
				self:CancelCharge()
				self._in_aim_mode = not self._in_aim_mode
				self._core_maid._cursor_bar:ChangeVisibility(self._in_aim_mode)
			end

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.KeyCode.Q
	)

	return
end

function ThrowableMelee:Equip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, true, SHIFTLOCK_OFFSET)

	self._core_maid._base_tool:Equip()
	self._core_maid.MeleeManager:Start()
	self:UserInput()
	return
end

function ThrowableMelee:Unequip(): nil
	self._in_aim_mode = false

	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	self._core_maid._cursor_bar:Hide()

	self._core_maid._base_tool:Unequip()
	self._connection_maid:DoCleaning()
	self._core_maid.Animator:DoCleaning()
	self._core_maid.MeleeManager:Stop()

	self._core_maid.StaminaObject:Clear()

	self:CancelCharge()

	if self._swing_trail then
		self._swing_trail.Enabled = false
	end
	return
end

function ThrowableMelee:Destroy(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	if self._swing_trail then
		self._swing_trail.Enabled = false
	end

	self:CancelCharge()

	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self._in_aim_mode = false
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
function ThrowableMelee.new(tool_obj: Tool, tool_data: { [string]: any }): SwordType
	local self = setmetatable({}, ThrowableMelee)

	local swing_debounce: number = if tool_data.SwingDebounce then tool_data.SwingDebounce else DEFAULT_SWING_DEBOUNCE
	local swing_duration: number = if tool_data.SwingDuration then tool_data.SwingDuration else DEFAULT_SWING_DURATION

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj
	self._in_aim_mode = false

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._attack_number = 1
	self._stability_duration = if tool_data.StabilityDuration
		then tool_data.StabilityDuration
		else DEFAULT_STABILITY_DURATION
	self._charge_duration = if tool_data.ChargeDuration then tool_data.ChargeDuration else DEFAULT_CHARGE_DURATION

	self._attack_count = if tool_data.StandardAttacks then #tool_data.StandardAttacks else DEFAULT_ATTACK_COUNT

	self._standard_attack_stamina = if tool_data.StandardStamina
		then tool_data.StandardStamina
		else DEFAULT_SWING_STAMINA_REQ

	self._sprint_cooldown = if tool_data.SprintCooldown then tool_data.SprintCooldown else DEFAULT_SPRINT_COOLDOWN
	self._parry_stamina_req = if tool_data.ParryStaminaReq then tool_data.ParryStaminaReq else DEFAULT_PARRY_STAMINA_REQ

	self._core_maid.CooldownManager = self.Core.CooldownClass.new({ { SWING_DEBOUNCE_NAME, swing_debounce } })
	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid.StaminaObject = self.Core.PlayerMovement.CreateStaminaObject()

	self._core_maid.MeleeManager =
		self.Core.Components[MELEE_COMPONENT_PATH].new(tool_obj, tool_data, swing_duration, self._core_maid.Animator)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)
	self._core_maid._charge_object = self.Core.Components[CHARGE_CLASS_PATH].new()

	self._core_maid._cursor_bar = self.Core.UIManager.GetCursorBar()

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

return ThrowableMelee
