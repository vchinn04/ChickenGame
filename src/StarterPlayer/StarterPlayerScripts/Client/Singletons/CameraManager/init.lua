local CameraManager = {
	Name = "CameraManager",
}
--[[
	<description>
		This manager is responsible for camera related effects 
		and managing the camera. 
	</description> 
	
	<API>
		CameraManager.GetMouseHit() ---> Vector3
			-- Return the niyse 3D location, useful for musket shot. 
		
		CameraManager.GetLookVector() ---> Vector3
			-- Return the camera LookVector

		CameraManager.Blur(duration: number): nil
			-- Create a blur effect that fades out in "duration" period. 
			duration: number ---> How long it takes for blur effect to fade out 

		CameraManager.Impulse(velocity_vector: Vector3, damp: number?, speed: number?) ---> nil
			-- Impulse a camera in a specified direction using a spring.
			velocity_vector : Vector3 -- Direction camera is impulsed
			damp: number? ---> Damp amount, DEFAULT is 0.5 
			speed: number? ---> Custom impulse speed, DEFAULT is 20
			
		CameraManager.ChangeFOV(new_fov : number, duration : number, start_fov : number?, acc_tween : boolean?) ---> nil
			-- Smoothly change the camera's FOV specifying the duration of change
			new_fov : number -- FOV changing to
			duration : number -- duration of tween
			start_fov : number? -- is needed if need an accurate tweening duration if player switches in between. When acc_tween is true
			acc_tween : boolean? -- set to true if need an accurate tweening duration if player switches in between

		CameraManager.FirstPerson(status: boolean): nil
			-- Place player in first person view or 3rd person view 
			status: boolean -- True: first person view, False: third person view 

		CameraManager.FocusCamera(object: Instance, player_dist: number, camera_dist: number, offset: Vector3?, tween_time: number?, tween_dist: number?) ---> Promise 
			-- Focus camera on specific object. Make camera look at object and move the camera to look at player and object. 
			object: Instance -- Object on which to focus
			player_dist: number -- Distance to player
			camera_dist: number -- Distance from object to final Camera position
			offset: Vector3? -- Offset to apply to camera position. DEFAULT: UP_VECTOR
			tween_time: number? -- Duration of tween. DEFAULT: 0.5 
			tween_dist: number? -- Distance expected to travel in "tween_time", DEFAULT: 7

		CameraManager.UnfocusCamera() ---> nil
			-- Revert camera to custom mode and cancel focus tween if it didn't complete. 

		CameraManager.EventHandler() ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwayClass = require(script:WaitForChild("Sway"))
local CameraShakerClass = require(script:WaitForChild("CameraShaker"))
local ShiftLockClass = require(script:WaitForChild("CustomCamera"))

local Core
local Maid
local Shake_Instances = {}
local UP_VECTOR = Vector3.new(0, 1, 0)

local DEFAULT_MIN_ZOOM: number = 5
local DEFAULT_MAX_ZOOM: number = 10
local DEFAULT_FOV: number = 70

--*************************************************************************************************--

function CameraManager.CreateTestPart(pos)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Parent = workspace
	p.Size = Vector3.new(0.15, 0.15, 0.15)
	p.Position = pos
end

function CameraManager.GetMouseHit(): Vector3
	local mouse_location: Vector2 = UserInputService:GetMouseLocation()
	local mouse_hit: Vector3 = Core.Camera:ScreenPointToRay(mouse_location.X, mouse_location.Y, 1000).Origin

	return mouse_hit
end

function CameraManager.GetLookVector(): Vector3
	return Core.Camera.CFrame.LookVector
end

function CameraManager.Blur(duration: number): nil
	local blur_effect: BlurEffect = Instance.new("BlurEffect")
	local blur_tween_in: Tween = TweenService:Create(blur_effect, TweenInfo.new(0.15), { Size = 11 })
	local blur_tween_out: Tween = TweenService:Create(blur_effect, TweenInfo.new(duration), { Size = 0 })

	blur_effect.Size = 0
	blur_effect.Parent = Core.Lighting
	blur_effect.Enabled = true

	Core.Utils.Promise
		.new(function(resolve, _, _)
			blur_tween_in:Play()
			blur_tween_in.Completed:Wait()
			resolve()
		end)
		:andThen(function()
			return Core.Utils.Promise.new(function(resolve)
				blur_tween_out:Play()
				blur_tween_out.Completed:Wait()
				resolve()
			end)
		end)
		:finally(function()
			blur_effect:Destroy()
		end)

	return
end

function CameraManager.Impulse(velocity_vector: Vector3, damp: number?, speed: number?): nil
	Maid._impulse_spring.Damper = 0.5
	Maid._impulse_spring.Speed = 20

	if damp then
		Maid._impulse_spring.Damper = damp
	end

	if speed then
		Maid._impulse_spring.Speed = speed
	end

	Maid._impulse_spring:Impulse(velocity_vector)
	Maid.__impulse_connection = RunService.RenderStepped:Connect(function(): nil
		local spring_velocity: Vector3 = Maid._impulse_spring["Velocity"]
		Core.Camera.CFrame = Core.Camera.CFrame * CFrame.new(spring_velocity)
		if spring_velocity.Magnitude <= 0.01 then
			Maid.__impulse_connection = nil
		end
		return
	end)

	return
end

function CameraManager.ChangeFOV(new_fov: number, duration: number, start_fov: number?, acc_tween: boolean?): nil
	if new_fov == Core.Camera.FieldOfView then
		return
	end
	local wait_time: number = if acc_tween and start_fov
		then math.abs(Core.Camera.FieldOfView - new_fov) / math.abs(new_fov - start_fov) * duration
		else duration

	CameraManager.__FOVTween = TweenService:Create(
		Core.Camera,
		TweenInfo.new(wait_time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ FieldOfView = new_fov }
	)

	CameraManager.__FOVTween:Play()

	return
end

function CameraManager.FirstPerson(status: boolean): nil
	if status then
		Core.Player.CameraMinZoomDistance = 0
		Core.Player.CameraMaxZoomDistance = 0
	else
		Core.Player.CameraMaxZoomDistance = DEFAULT_MAX_ZOOM
		Core.Player.CameraMinZoomDistance = DEFAULT_MIN_ZOOM
	end

	return
end

function CameraManager.FocusCamera(
	object: Instance,
	player_dist: number,
	camera_dist: number,
	offset: Vector3?,
	tween_time: number?,
	tween_dist: number?
): { [string]: any }
	Core.Camera.CameraType = Enum.CameraType.Scriptable

	if not tween_time then
		tween_time = 0.5
	end
	if not tween_dist then
		tween_dist = 7
	end
	if not offset then
		offset = UP_VECTOR
	end

	local object_position: Vector3 = if object:IsA("Model") then object:GetPivot().Position else object.Position

	local cam_cframe: CFrame = Core.Camera.CFrame
	local cam_pos: Vector3 = cam_cframe.Position
	local player_height: number = Core.HumanoidRootPart.Position.Y

	local object_heightlesss_position: Vector3 = Vector3.new(object_position.X, player_height, object_position.Z)
	local direction_to_humroot: Vector3 = (Core.HumanoidRootPart.Position - object_heightlesss_position).Unit
	local mid_point: Vector3 = object_position + (direction_to_humroot * player_dist / 2)

	local perpendicular_direction_one: Vector3 = (direction_to_humroot:Cross(UP_VECTOR)).Unit
	local perpendicular_direction_two: Vector3 = perpendicular_direction_one * -1

	local fin_pos_option1: Vector3 = mid_point + perpendicular_direction_one * camera_dist
	local fin_pos_option2: Vector3 = mid_point + perpendicular_direction_two * camera_dist

	local fin_pos: Vector3 = if ((cam_pos - fin_pos_option1).Magnitude < (cam_pos - fin_pos_option2).Magnitude)
		then fin_pos_option1
		else fin_pos_option2

	local wait_time: number = (tween_time / tween_dist) * (fin_pos - cam_pos).Magnitude

	CameraManager._focus_tween = Core.Utils.Promise.new(function(resolve, _, onCancel)
		local focus_tween = TweenService:Create(
			Core.Camera,
			TweenInfo.new(wait_time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ CFrame = CFrame.new(fin_pos + offset, object_position + (direction_to_humroot * player_dist / 2.25)) }
		)

		if onCancel(function()
			focus_tween:Cancel()
		end) then
			return
		end

		focus_tween.Completed:Connect(resolve)
		focus_tween:Play()
	end)

	return
end

function CameraManager.UnfocusCamera(): nil
	Core.Camera.CameraType = Enum.CameraType.Custom
	if CameraManager._focus_tween then
		CameraManager._focus_tween:cancel()
	end
	CameraManager._focus_tween = nil
end

function CameraManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("CameraLock", function(status: boolean, offset: Vector3?)
		if offset then
			Maid._shiftlock:SetOffset(offset)
		end
		Maid._shiftlock:ToggleShiftLock(status)
	end))

	Maid:GiveTask(Core.Subscribe("TakeAim", function(status: boolean, new_fov: number)
		if status then
			local updated_fov = if new_fov ~= nil then new_fov else 60

			CameraManager.ChangeFOV(updated_fov, 0.25)
		else
			CameraManager.ChangeFOV(70, 0.25)
		end
	end))

	Maid:GiveTask(Core.Subscribe("ObstacleHit", function(_)
		Maid._camera_shaker:ShakeOnce(1.25, 5, 0.2, 1.25)
	end))

	Maid:GiveTask(Core.Subscribe("Sprint", function(status: string): nil
		if status then
			CameraManager.ChangeFOV(85, 0.25)
			Maid._movement_sway_object:AdjustSway(7.75, 135)
		else
			Maid._movement_sway_object:AdjustSway(0.65, 175)
			CameraManager.ChangeFOV(70, 0.25)
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("ThrowCharge", function(status: boolean, duration: number, ret_fov: number): nil
		if status then
			CameraManager.ChangeFOV(95, duration)
		else
			if not ret_fov then
				ret_fov = DEFAULT_FOV
			end
			CameraManager.ChangeFOV(ret_fov, 0.25)
		end
		return
	end))

	Maid:GiveTask(
		Core.Subscribe(
			"ZoomFOV",
			function(status: boolean, zoom_amount: number, duration: number, limits: { number }): nil
				if status then
					local new_fov = Core.Camera.FieldOfView + zoom_amount
					if new_fov > limits[1] then
						new_fov = limits[1]
					elseif new_fov < limits[2] then
						new_fov = limits[2]
					end
					CameraManager.ChangeFOV(new_fov, duration)
				else
					CameraManager.ChangeFOV(DEFAULT_FOV, 0.25)
				end
				return
			end
		)
	)

	Maid:GiveTask(Core.Subscribe("ChargeOverload", function(status: boolean): nil
		if Shake_Instances["ChargeOverload"] then
			Shake_Instances["ChargeOverload"]:StartFadeOut(0.15)
		end

		if status then
			Shake_Instances["ChargeOverload"] = Maid._camera_shaker:StartShake(1, 3, 0.15)
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("ThrowSuccess", function(): nil
		CameraManager.Impulse(Core.HumanoidRootPart.CFrame.LookVector * 2.5, 0.75, 9.5)
		return
	end))

	Maid:GiveTask(Core.Subscribe("Movement", function(status: string): nil
		if status then
			Maid._movement_sway_object:Sway()
		else
			Maid._movement_sway_object:CancelSway()
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("MeleeHit", function(_): nil
		Maid._camera_shaker:ShakeOnce(3.25, 5, 0.1, 0.45)
		return
	end))

	Maid:GiveTask(Core.Subscribe("MiningTrigger", function(status: boolean, inst: Instance): nil
		if status then
			CameraManager.FocusCamera(inst, 3.5, 6, UP_VECTOR, 0.6, 7)
		else
			CameraManager.UnfocusCamera()
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("ResourceTrigger", function(status: boolean, inst: Instance): nil
		if status then
			CameraManager.FocusCamera(inst, 3.5, 6, UP_VECTOR, 0.6, 7)
		else
			CameraManager.UnfocusCamera()
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("CameraShake", function(magnitude, roughness, fadeInTime, fadeOutTime)
		Maid._camera_shaker:ShakeOnce(magnitude, roughness, fadeInTime, fadeOutTime) -- magnitude, roughness, fadeInTime, fadeOutTime, posInfluence, rotInfluence
	end))

	Maid:GiveTask(Core.Subscribe("FirstPerson", function(status: boolean)
		CameraManager.FirstPerson(status)
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("Parry").OnClientEvent:Connect(function()
		Maid._camera_shaker:ShakeOnce(2.1, 9, 0.15, 1.5) -- magnitude, roughness, fadeInTime, fadeOutTime, posInfluence, rotInfluence
		CameraManager.Blur(1.5)
		Core.Fire("Blind", 1.5)
		Core.Fire("Parry")
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("Block").OnClientEvent:Connect(function(hit_part: Instance)
		local direction: Vector3 = (hit_part.Position - Core.HumanoidRootPart.Position)
		local heightless_dimensional_direction: Vector3 = Vector3.new(direction.X, direction.Y, 0).Unit

		CameraManager.Impulse(heightless_dimensional_direction * 2.75, 0.45, 20)
		Maid._camera_shaker:ShakeOnce(1.35, 7.9, 0.15, 0.75) -- magnitude, roughness, fadeInTime, fadeOutTime, posInfluence, rotInfluence
		Core.Fire("Block")
	end))

	return
end

function CameraManager.Start(): nil
	Maid._impulse_spring = Core.Utils.Spring.new(Vector3.new(0, 0, 0))
	Maid._camera_shaker = CameraShakerClass.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame: CFrame): nil
		Core.Camera.CFrame *= shakeCFrame
		return
	end)
	Maid._camera_shaker:Start()
	Maid._impulse_spring.Damper = 0.5
	Maid._impulse_spring.Speed = 20
	Maid._movement_sway_object = SwayClass.new(2, 175)

	Maid._shiftlock = ShiftLockClass.new()

	CameraManager.EventHandler()
	return
end

function CameraManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()

	return
end

function CameraManager.Reset(): nil
	Maid:DoCleaning()
	return
end

return CameraManager
