local StandardMelee = {}
StandardMelee.__index = StandardMelee
--[[
	<description>
		This class provides the functionalities for the basic 
		Melee weapon using the Melee component 
	</description> 
	
	<API>
		StandardMeleeObject:GetId(): string
			-- Returns id of tool assigned to instance

		StandardMeleeObject:StandardSwing() ---> boolean?
			-- Perform a standard swing and return true if swing goes through. 

		StandardMeleeObject:Attack() ---> nil 
			-- Perform attack and if it goes through increment attack number 

		StandardMeleeObject:Block(status) ---> nil 
			-- Block (true) or unblock (false) depending on status 
			status: boolean -- true to block and false to unblock 

		StandardMeleeObject:Parry() ---> nil 
			-- Perform parry action if conditions are met (stamina, etc) 
			
		StandardMeleeObject:Deflect() ---> nil 
			-- Reverse current swing animation, OR play the last swing in reverse to create a 
			   "deflection" effect. 

		StandardMeleeObject:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		StandardMeleeObject:Unequip() --> void
			-- Tares down connections such as input, etc
			
		StandardMeleeObject:Destroy() --> void
			-- Tares down all connections and destroys components used (E.g. Melee)

		Sword.new(tool_obj: Tool, tool_data: { [string]: any }) ---> StandardMelee
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
local CANCEL_SPRINT_EVENT: string = "CancelSprint"
local SWING_DEBOUNCE_NAME: string = "Swing_Debounce"
local ATTACK_PREFIX: string = "Hit"
local SHIFT_LOCK_EVENT: string = "CameraLock"

local PARRY_SERVER_EVENT: string = "Parry"

local BLOCKING_STATE: string = "Blocking"

local DEFAULT_SPRINT_COOLDOWN: number = 3
local DEFAULT_PARRY_STAMINA_REQ: number = 25
local DEFAULT_ATTACK_COUNT: number = 3
local DEFAULT_SWING_STAMINA_REQ: number = 45
local DEFAULT_SWING_DEBOUNCE: number = 0.65
local DEFAULT_SWING_DURATION: number = 0.65

local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(2.25, 0.25, 0)

--*************************************************************************************************--

function StandardMelee:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end

	return
end

function StandardMelee:StandardSwing(): boolean?
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
			self._swing_anim = nil
			self._connection_maid.SwingCompletionEvent = nil

			if self._swing_trail then
				self._swing_trail.Enabled = false
			end
		end)
	end

	self._core_maid.MeleeManager:Attack()

	return true
end

function StandardMelee:Attack(): nil
	local success: boolean = self:StandardSwing()
	if success then
		self._attack_number += 1
		if self._attack_number > self._attack_count then
			self._attack_number = 1
		end
	end
	return
end

function StandardMelee:Block(status: boolean): nil
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

function StandardMelee:Parry(): nil
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

function StandardMelee:Deflect(): nil
	if self._swing_anim then
		self._core_maid.Animator:SetSpeed(self._swing_anim, -1)
		return
	end
	if self._last_anim_name then
		self._core_maid.Animator:PlayReverse(self._tool_data.AnimationData[self._last_anim_name])
	end
	return
end

--[[
	<description>
		Sets up the user input connections such as swinging.
	</description> 
		
--]]
function StandardMelee:UserInput(): nil
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
	end, true, Enum.KeyCode.Q)

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

	return
end

function StandardMelee:Equip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, true, SHIFTLOCK_OFFSET)
	self._core_maid._base_tool:Equip()
	self._core_maid.MeleeManager:Start()
	self:UserInput()
	return
end

function StandardMelee:Unequip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	self._core_maid._base_tool:Unequip()
	self._connection_maid:DoCleaning()
	self._core_maid.Animator:DoCleaning()
	self._core_maid.MeleeManager:Stop()

	self._core_maid.StaminaObject:Clear()

	if self._swing_trail then
		self._swing_trail.Enabled = false
	end

	return
end

function StandardMelee:Destroy(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	if self._swing_trail then
		self._swing_trail.Enabled = false
	end

	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

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
function StandardMelee.new(tool_obj: Tool, tool_data: { [string]: any }): SwordType
	local self = setmetatable({}, StandardMelee)

	local swing_debounce: number = if tool_data.SwingDebounce then tool_data.SwingDebounce else DEFAULT_SWING_DEBOUNCE
	local swing_duration: number = if tool_data.SwingDuration then tool_data.SwingDuration else DEFAULT_SWING_DURATION

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._attack_number = 1
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

return StandardMelee
