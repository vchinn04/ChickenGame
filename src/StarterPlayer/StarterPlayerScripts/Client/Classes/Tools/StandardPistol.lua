local StandardPistol = {}
StandardPistol.__index = StandardPistol
--[[
	<description>
		This class provides the functionalities for the standard 
		pistol. There are only ranged functionalities. 
	</description> 
	
	<API>
		StandardPistolObject:GetId(): string
			-- Returns id of tool assigned to instance

		StandardPistolObject:Attack() ---> nil 
			-- Perform attack and if it goes through increment attack number 
		
		StandardPistolObject:Ranged() ---> nil
			-- Fire a pistol shot if it is loaded. 

		StandardPistolObject:Reload() ---> nil
			-- Attempt to reload pistol if neccessary ammunition is present. Will
			work unless no ammunition or pistol is FULLY loaded. Takes the duration of 
			the animation given.

		StandardPistolObject:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		StandardPistolObject:Unequip() --> void
			-- Tares down connections such as input, etc
			
		StandardPistolObject:Destroy() --> void
			-- Tares down all connections and destroys components used (E.g. Melee)

		StandardPistol.new(tool_obj: Tool, tool_data: { [string]: any }) ---> StandardPistolObject
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

local MUSKET_STATES: {} = {
	Rest = 1,
	Reloading = 2,
	Presenting = 3,
}

local STANDARD_FIRE_REMOTE_EVENT: string = "StandardFire"
local CANCEL_SPRINT_EVENT: string = "CancelSprint"
local CANCEL_JUMP_EVENT: string = "CancelJump"

local SHIFT_LOCK_EVENT: string = "CameraLock"
local RELOAD_REMOTE_EVENT: string = "Reload"
local PRESENT_EVENT: string = "TakeAim"
local DEFAULT_PRESENT_FOV: number = 45
local SHOOT_EVENT: string = "ThrowSuccess"

local DEFAULT_SPRINT_COOLDOWN: number = 3
local DEFAULT_AMMUNITION_ID: string = "Flintlock"

local SHIFTLOCK_OFFSET: Vector3 = Vector3.new(2.5, 0.25, 0)

local SPEED_CHANGE_EVENT: string = "SpeedAction"
local SPEED_PRESENT_MULTIPLIER: number = 0.5
local SPEED_RELOAD_MULTIPLIER: number = 0.5

--*************************************************************************************************--

function StandardPistol:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardPistol:Attack(): nil
	if self._current_state:get() == MUSKET_STATES.Presenting then
		self:Ranged()
	end

	return
end

function StandardPistol:Ranged(): nil
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

function StandardPistol:Reload(): nil
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

function StandardPistol:UserInput(): nil
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

			if input_state == Enum.UserInputState.Begin then
				self:Attack()
			end

			return Enum.ContextActionResult.Pass
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

	self._connection_maid:GiveTask(self._state_observer:onChange(function()
		local current_state: number = self._current_state:get()

		if current_state == MUSKET_STATES.Presenting then
			self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Present)
			self.Core.Fire(SPEED_CHANGE_EVENT, "Present", SPEED_PRESENT_MULTIPLIER)
			self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Pistol", true)
			self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Pistol", true)
		elseif current_state == MUSKET_STATES.Reloading then
			self.Core.Fire(SPEED_CHANGE_EVENT, "Reload", SPEED_RELOAD_MULTIPLIER)
			self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Pistol", true)
			self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Pistol", true)
		else
			self.Core.Fire(SPEED_CHANGE_EVENT, "Reload", nil)
			self.Core.Fire(SPEED_CHANGE_EVENT, "Present", nil)
			self.Core.Fire(CANCEL_SPRINT_EVENT, nil, "Pistol", false)
			self.Core.Fire(CANCEL_JUMP_EVENT, nil, "Pistol", false)
		end

		if current_state ~= MUSKET_STATES.Presenting then
			self.Core.Fire(PRESENT_EVENT, false, self._present_fov)
			self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Idle)
			self._core_maid.Animator:StopAnimation(self._tool_data.AnimationData.Present)
		end

		return
	end))

	return
end

function StandardPistol:Equip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, true, SHIFTLOCK_OFFSET)

	self._core_maid._base_tool:Equip()
	self:UserInput()
	return
end

function StandardPistol:Unequip(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	if self._reload_promise then
		self._reload_promise:cancel()
		self._reload_promise = nil
	end

	self._current_state:set(MUSKET_STATES.Rest)

	self._core_maid._base_tool:Unequip()
	self._connection_maid:DoCleaning()
	self._core_maid.Animator:DoCleaning()

	self._core_maid.StaminaObject:Clear()

	return
end

function StandardPistol:Destroy(): nil
	self.Core.Fire(SHIFT_LOCK_EVENT, false)

	if self._reload_promise then
		self._reload_promise:cancel()
		self._reload_promise = nil
	end

	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self._current_state = nil

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
function StandardPistol.new(tool_obj: Tool, tool_data: { [string]: any }): SwordType
	local self = setmetatable({}, StandardPistol)

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._item_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. tool_data.Id)

	self._present_fov = if tool_data.PresentFOV then tool_data.PresentFOV else DEFAULT_PRESENT_FOV
	self._sprint_cooldown = if tool_data.SprintCooldown then tool_data.SprintCooldown else DEFAULT_SPRINT_COOLDOWN

	self._core_maid.CooldownManager = self.Core.CooldownClass.new({})
	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)
	self._core_maid.StaminaObject = self.Core.PlayerMovement.CreateStaminaObject()

	local bullet_id: string = self._tool_data.AmmoType
	if not bullet_id then
		bullet_id = DEFAULT_AMMUNITION_ID
	end

	self._bullet_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. bullet_id)

	self._current_state = self.Core.Fusion.Value(MUSKET_STATES.Rest)
	self._state_observer = self.Core.Fusion.Observer(self._current_state)

	if self._tool_data.SoundData then
		self._core_maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Client.Swing then
			self._core_maid._clone_swing_sound =
				self._core_maid.SoundObject:CloneSound(self._tool_data.SoundData.Client.Swing.Name, self._tool)
		end
	end
	return self
end

return StandardPistol
