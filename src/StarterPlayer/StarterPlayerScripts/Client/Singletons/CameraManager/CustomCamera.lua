local ShiftLock = {}
ShiftLock.__index = ShiftLock
--[[
	<description>
		This class provides the functionalities for a Smooth shift lock
        that adds smoothness to the Roblox's shift lock. It also provides 
		a smooth camera follow for when player is not in shiftlock mode.
	</description> 
	
	<API>
		ShiftLockObject:IsEnabled() ---> boolean
			-- Returns if shiftlock is enabled

		ShiftLockObject:SetMouseState(enable: boolean) ---> nil
			-- Lock or unlock mouse 
            enable: boolean -- True: lock, False: unlock

		ShiftLockObject:SetOffset(offset: Vector3) ---> nil
			-- Set a new offset 
            offset : Vector3 -- new offset

		ShiftLockObject:TransitionLockOffset(enable: boolean) ---> nil
			-- Change offset of camera based on shiftlock
			enable: boolean -- True: shiftlock offset, False: zero vector

		ShiftLockObject:ToggleShiftLock(enable: boolean) ---> nil
			-- Begin shiftlock of cancel it 
			enable: boolean -- True: begin shiftlock, False: cancel it
		ShiftLockObject:Destroy() --> void
			-- Tares down all connections and destroys ShiftLockObject

		ShiftLock.new() ---> ShiftLockObject
			-- Create a new ShiftLockObject
	</API>
	
	<Authors>
		RoGuruu (770772041)
        Credits: 
            rixtys - https://devforum.roblox.com/t/smoothshiftlock-module/2180708
	</Authors>
--]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CHARACTER_SMOOTH_ROTATION: boolean = true --// If your character should rotate smoothly or not
local CHARACTER_ROTATION_SPEED: number = 3 --// How quickly character rotates smoothly
local TRANSITION_SPRING_DAMPER: number = 0.7 --// Camera transition spring damper, test it out to see what works for you
local CAMERA_TRANSITION_IN_SPEED: number = 10 --// How quickly locked camera moves to offset position
local CAMERA_TRANSITION_OUT_SPEED: number = 14 --// How quickly locked camera moves back from offset position
local ZERO_VECTOR: Vector3 = Vector3.new(0, 0, 0)
local DEFAULT_OFFSET: Vector3 = Vector3.new(2.5, 0.25, 0)

--*************************************************************************************************--

function ShiftLock:IsEnabled(): boolean
	return self._enabled
end

function ShiftLock:SetMouseState(enable: boolean): nil
	UserInputService.MouseBehavior = (enable and Enum.MouseBehavior.LockCenter) or Enum.MouseBehavior.Default
	return
end

function ShiftLock:SetOffset(offset: Vector3): nil
	self._locked_camera_offset = offset
	return
end

function ShiftLock:TransitionLockOffset(enable: boolean): nil
	if enable then
		self._core_maid._camera_spring.Speed = CAMERA_TRANSITION_IN_SPEED
		self._core_maid._camera_spring.Target = self._locked_camera_offset
	else
		self._core_maid._camera_spring.Speed = CAMERA_TRANSITION_OUT_SPEED
		self._core_maid._camera_spring.Target = ZERO_VECTOR
	end
	return
end

function ShiftLock:ToggleShiftLock(enable: boolean): nil
	assert(typeof(enable) == typeof(false), "Enable value is not a boolean.")
	self._enabled = enable

	self:SetMouseState(self._enabled)
	self:TransitionLockOffset(self._enabled)
	self.Core.Humanoid.AutoRotate = not self._enabled

	if self._enabled then
		self._connection_maid:GiveTask(RunService.Heartbeat:Connect(function(delta)
			if self._enabled then
				if self.Core.Player:GetAttribute("CameraPositionLock") then
					return
				end

				if not self.Core.Humanoid.Sit and CHARACTER_SMOOTH_ROTATION then
					local _, y, _ = self.Core.Camera.CFrame:ToOrientation()

					self.Core.HumanoidRootPart.CFrame = self.Core.HumanoidRootPart.CFrame:Lerp(
						CFrame.new(self.Core.HumanoidRootPart.Position) * CFrame.Angles(0, y, 0),
						delta * 5 * CHARACTER_ROTATION_SPEED
					)
				elseif not self.Core.Humanoid.Sit then
					local _, y, _ = self.Core.Camera.CFrame:ToOrientation()

					self.Core.HumanoidRootPart.CFrame = CFrame.new(self.Core.HumanoidRootPart.Position)
						* CFrame.Angles(0, y, 0)
				end
			end
		end))
	else
		self._connection_maid:DoCleaning()
	end

	return
end

function ShiftLock:Destroy(): nil
	self:ToggleShiftLock(false)

	self._core_maid:DoCleaning()
	self._connection_maid:DoCleaning()

	self._core_maid = nil
	self._connection_maid = nil

	return
end

function lerp(a, b, c)
	return a + (b - a) * c
end

function ShiftLock.new(): {}
	local self = setmetatable({}, ShiftLock)

	self.Core = _G.Core

	self._enabled = false

	self._locked_camera_offset = DEFAULT_OFFSET

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid._camera_spring = self.Core.Utils.Spring.new(ZERO_VECTOR)
	self._core_maid._camera_spring.Damper = TRANSITION_SPRING_DAMPER

	self._connection_maid = self.Core.Utils.Maid.new()

	self._head = self.Core.Character:WaitForChild("Head")
	local XOffset = 0
	local ZOffset = 0

	self._core_maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
		if self._head.LocalTransparencyModifier > 0.6 then
			return
		end

		if not self.Core.HumanoidRootPart then
			return
		end

		local camCF = self.Core.Camera.CFrame
		local distance = (self._head.Position - camCF.p).Magnitude

		if distance > 1 then
			self.Core.Camera.CFrame = (camCF * CFrame.new(self._core_maid._camera_spring.Position))

			if self._enabled and (UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter) then
				self:SetMouseState(self._enabled)
			else
				camCF = self.Core.Camera.CFrame
				local flatCamLookVector = (camCF.LookVector * Vector3.new(1, 0, 1)).Unit

				local flatCamCFrame = CFrame.new(Vector3.zero, flatCamLookVector) -- cframe from the flat vector
				local localMovement = flatCamCFrame:VectorToObjectSpace(self.Core.HumanoidRootPart.Velocity / 50) -- turn velocity from world to the flat camera cframe
				local xMovement = localMovement.X -- calculate the X movement based on the camera
				local zMovement = localMovement.Z
				local t = dt * 60

				XOffset = lerp(XOffset, xMovement, math.pow(0.1, t))
				ZOffset = lerp(ZOffset, zMovement, math.pow(0.1, t))

				self.Core.Camera.CFrame = camCF + flatCamCFrame.RightVector * -XOffset + flatCamLookVector * ZOffset -- add negative offset to camera CFrame
			end
		end
	end))

	return self
end

return ShiftLock
