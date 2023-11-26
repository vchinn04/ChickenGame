local StandardBow = {}
StandardBow.__index = StandardBow
--[[
	<description>
		This class provides the functionalities for the standard bow 
		system. Could also be used for other basic chargable ranged 
		weapons that do not have melee functionalities. 
	</description> 
	
	<API>
		StandardBowObject:GetId(): string
			-- Returns id of tool assigned to instance

		StandardBowObject:Ranged(status: boolean) ---> nil
			-- Provides the charging and throwing functionality. If status it true, begin charging 
			and once the charge is complete after a period of type begin screen shake for overcharge, 
			status : boolean -- set to true to charge and set to false to throw (if charge is above a min threshold)

		StandardBowObject:CancelCharge() ---> Cancel the charge and the overcharge promise. Set 
		current charge to 0. Reset the UI Charge indicator. 
			
		StandardBowObject:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		StandardBowObject:Unequip() --> void
			-- Tares down connections such as input, etc
			
		StandardBowObject:Destroy() --> void
			-- Tares down all connections and destroys components used (E.g. Melee)

		StandardBow.new(tool_obj: Tool, tool_data: { [string]: any }) ---> StandardBowObject
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
local CHARGE_CLASS_PATH: string = "Misc/ChargeClass"

local SHIFT_LOCK_EVENT: string = "CameraLock"
local PRESENT_EVENT: string = "TakeAim"
local SHOOT_EVENT: string = "ThrowSuccess"
local CANCEL_SPRINT_EVENT: string = "CancelSprint"
local CANCEL_JUMP_EVENT: string = "CancelJump"

local DEFAULT_SPRINT_COOLDOWN: number = 3
local DEFAULT_CHARGE_DURATION: number = 3
local DEFAULT_STABILITY_DURATION: number = 3

local DEFAULT_PRESENT_FOV: number = 45
local CHARGE_THRESHOLD: number = 100
local CHARGE_EVENT: string = "ThrowCharge"
local CHARGE_OVERLOAD_EVENT: string = "ChargeOverload"
local LAUNCH_REMOTE_EVENT: string = "StandardFire"

local DEFAULT_AMMUNITION_ID: string = "Arrow"

local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(2.75, 0.25, 0)

local SPEED_CHANGE_EVENT: string = "SpeedAction"
local SPEED_PRESENT_MULTIPLIER: number = 0.5

--*************************************************************************************************--

function StandardBow:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardBow:Ranged(status: boolean): nil
	if not self._arrow_entry then
		local arrow_id: string = self._tool_data.AmmoType

		if not arrow_id then
			arrow_id = DEFAULT_AMMUNITION_ID
		end

		self._arrow_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. arrow_id)
	end

	if not self._arrow_entry or self._arrow_entry.Amount <= 0 then
		return
	end

	if status then
		if not self._in_aim_mode then
			self.Core.Fire(CHARGE_EVENT, true, self._charge_duration)
		end

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
			self.Core.Fire(SHOOT_EVENT)
			self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(
				LAUNCH_REMOTE_EVENT,
				{ Direction = self.Core.CameraManager.GetLookVector(), Charge = current_charge }
			)
		end
	end

	return
end

function StandardBow:CancelCharge(): nil
	self._core_maid._charge_object:CancelCharge()
	self._core_maid._cursor_bar:Reset()

	if not self._in_aim_mode then
		self.Core.Fire(CHARGE_EVENT, false, self._charge_duration)
	end

	if self._charge_overload_promise then
		self._charge_overload_promise:cancel()
		self._charge_overload_promise = nil
	end

	self.Core.Fire(CHARGE_OVERLOAD_EVENT, false)
	return
end

function StandardBow:UserInput(): nil
	self._connection_maid:GiveBindAction("BowCharge")
	ContextActionService:BindAction(
		"BowCharge",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			if self.Core.ActionStateManager:getState().MovementAbility then
				return Enum.ContextActionResult.Pass
			end

			if input_state == Enum.UserInputState.Cancel then
				return Enum.ContextActionResult.Pass
			end

			self:Ranged(input_state == Enum.UserInputState.Begin)

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.UserInputType.MouseButton1
	)

	self._connection_maid:GiveBindAction("Present")
	ContextActionService:BindAction(
		"Present",
		function(_, input_state: Enum.UserInputState, _): Enum.ContextActionResult?
			self:CancelCharge()
			self._core_maid._cursor_bar:Reset()

			local input_began: booelan = input_state == Enum.UserInputState.Begin
			self._in_aim_mode = input_began

			if input_began then
				self.Core.Fire(SPEED_CHANGE_EVENT, "Present", SPEED_PRESENT_MULTIPLIER)
				self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Bow", true)
				self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Bow", true)
				self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Present)
			else
				self.Core.Fire(SPEED_CHANGE_EVENT, "Present", nil)
				self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Bow", false)
				self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Bow", false)
				self._core_maid.Animator:StopAnimation(self._tool_data.AnimationData.Present)
			end

			self.Core.Fire(PRESENT_EVENT, input_began, self._present_fov)

			return Enum.ContextActionResult.Pass
		end,
		true,
		Enum.UserInputType.MouseButton2
	)

	return
end

function StandardBow:Equip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, true, SHIFTLOCK_OFFSET)

	self._core_maid._base_tool:Equip()
	self._core_maid._cursor_bar:Show()
	self:UserInput()
	return
end

function StandardBow:Unequip(): nil
	self._in_aim_mode = false

	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	self.Core.Fire(SPEED_CHANGE_EVENT, "Present", nil)
	self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Bow", false)
	self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Bow", false)

	self._core_maid._cursor_bar:Hide()

	self._core_maid._base_tool:Unequip()

	self._connection_maid:DoCleaning()
	self._core_maid.Animator:DoCleaning()

	self._core_maid.StaminaObject:Clear()

	self:CancelCharge()

	if self._swing_trail then
		self._swing_trail.Enabled = false
	end

	return
end

function StandardBow:Destroy(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	self:CancelCharge()

	self.Core.Fire(SPEED_CHANGE_EVENT, "Present", nil)
	self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Bow", false)
	self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Bow", false)

	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self._in_aim_mode = false
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
function StandardBow.new(tool_obj: Tool, tool_data: { [string]: any }): SwordType
	local self = setmetatable({}, StandardBow)

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj

	self._in_aim_mode = false
	self._present_fov = if tool_data.PresentFOV then tool_data.PresentFOV else DEFAULT_PRESENT_FOV
	self._sprint_cooldown = if tool_data.SprintCooldown then tool_data.SprintCooldown else DEFAULT_SPRINT_COOLDOWN
	self._stability_duration = if tool_data.StabilityDuration
		then tool_data.StabilityDuration
		else DEFAULT_STABILITY_DURATION
	self._charge_duration = if tool_data.ChargeDuration then tool_data.ChargeDuration else DEFAULT_CHARGE_DURATION

	local arrow_id: string = self._tool_data.AmmoType
	if not arrow_id then
		arrow_id = DEFAULT_AMMUNITION_ID
	end

	self._arrow_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. arrow_id)

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.CooldownManager = self.Core.CooldownClass.new({})
	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid.StaminaObject = self.Core.PlayerMovement.CreateStaminaObject()

	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)
	self._core_maid._charge_object = self.Core.Components[CHARGE_CLASS_PATH].new()
	self._core_maid._cursor_bar = self.Core.UIManager.GetCursorBar()

	if self._tool_data.SoundData then
		self._core_maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Client.Swing then
			self._core_maid._clone_swing_sound =
				self._core_maid.SoundObject:CloneSound(self._tool_data.SoundData.Client.Swing.Name, self._tool)
		end
	end

	return self
end

return StandardBow
