local Sway = {}
Sway.__index = Sway

--[[
	<description>
		This class simulates camera swaying motion.
	</description> 
	
	<API>
		SwayObject:Sway() : nil
			-- Impulse a camera in a specified direction using a spring.
			velocity_vector : Vector3 -- Direction camera is impulsed
			
		SwayObject:AdjustSway(damp_amount: number, sway_limit: number) : nil
			-- Smoothly change the camera's FOV specifying the duration of change
			damp_amount : number -- How damped/smooth tha motion is 
			sway_limit : number -- Divisor which affects how far in each direction camera sways

		Sway:CancelSway()
			--	Cancel the sway effect, wait for camera to reset to default position and stop it.

		CameraManager.EventHandler() ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local RunService = game:GetService("RunService")
--*************************************************************************************************--

function Sway:Sway(): nil
	self.Maid.CancelConnection = nil
	self.Maid.SwayConnection = RunService.RenderStepped:Connect(function(dt)
		self.__run_duration += dt
		self.Camera.CFrame = self.Camera.CFrame
			* CFrame.Angles(0, 0, math.sin(self.__run_duration * self.__damp_amount) / self.__sway_limit)
	end)
	return
end

function Sway:AdjustSway(damp_amount: number, sway_limit: number)
	self.__damp_amount = damp_amount
	self.__sway_limit = sway_limit
	return
end

function Sway:CancelSway(): nil
	self.Maid.CancelConnection = RunService.RenderStepped:Connect(function(dt)
		local cam_cframe = self.Camera.CFrame
		local cam_rot = cam_cframe - cam_cframe.Position
		if cam_rot.z == 0 then
			self.__run_duration = 0
			self.Maid.SwayConnection = nil
			self.Maid.CancelConnection = nil
		end
	end)
	return
end

function Sway.new(damp_amount, sway_limit)
	local self = setmetatable({}, Sway)
	self.Core = _G.Core
	self.__damp_amount = damp_amount
	self.__sway_limit = sway_limit
	self.__run_duration = 0
	self.Maid = self.Core.Utils.Maid.new()
	self.Camera = self.Core.Camera
	return self
end

function Sway:Destroy()
	self.__damp_amount = nil
	self.__sway_limit = nil
	self.__run_duration = nil
	self.Core = nil
	self.Maid:DoCleaning()
	self.Maid = nil
	self = nil
end

return Sway
