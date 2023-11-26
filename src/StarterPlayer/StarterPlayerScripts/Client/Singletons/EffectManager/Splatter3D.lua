local Splatter3D = {}
Splatter3D.__index = Splatter3D

--[[
	<description>
		This manager is responsible for particle effects and other VFX
	</description> 
	
	<API>
		Splatter3DObject:Splatter(center_part: Instance, callback: <a>(a) -> (), effect_interval: number, effect_duration: number) ---> nil
			-- Create a splatter effect with the part provided which MUST have a "Trail" object with "Enable" property.
			center_part: Instace ---> From where effect is emitted 
			callback: <a>(a) -> () ---> Called for every "splat" that hits ground. Raycast results are passed in. 
			effect_interval: number ---> How long between each splat emittion. 
			effect_duration: number ---> How long effect should continue

		Splatter3DObject:PrintStats() ---> nil 
			-- Print how many total effect parts where created and how many destroyed. Useful for debugging. 
		
		(WIP) Splatter3DObject:Destroy() ---> nil 
			--- Destroy Splatter3DObject

		Splatter3D.new(raycast_params, effect_part: Instance, x_limits: { number }, y_limits: { number }, z_limits: { number }, gravity: number) ---> Splatter3DObject
			-- Create a new Splatter3DObject
			raycast_params ---> Initial raycast params
			effect_part: Instance ---> Splat part with "Trail" inside it.
			x_limits: { number } ---> An array with 2 entries of form {low_distance_lim, high_distance_lim} in studes
			y_limits: { number } ---> An array with 2 entries of form {low_distance_lim, high_distance_lim} in studes
			z_limits: { number } ---> An array with 2 entries of form {low_distance_lim, high_distance_lim} in studes
			gravity: number ---> Amount of gravity to be used to affect splatter parts
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

local RunService = game:GetService("RunService")

local total_projectiles = 0
local total_destroyed = 0

function Splatter3D:Splatter(
	center_part: Instance,
	callback: <a>(a) -> (),
	effect_interval: number,
	effect_duration: number
): nil
	self.__raycast_params:AddToFilter(center_part.Parent)
	self.__raycast_params:AddToFilter(self.Core.Character)

	task.spawn(function()
		for _ = 0, effect_duration, effect_interval do
			total_projectiles += 1
			local projectile: Instance = self.PartCache:GetPart()
			local trail: Trail = projectile:WaitForChild("Trail")
			local init_pos: Vector3 = center_part.Position

			projectile.Position = init_pos

			local y_component: number = math.random(self.__y_magnitude[1], self.__y_magnitude[2])
			local x_component: number = math.random(self.__x_limits[1], self.__x_limits[2])
			local z_component: number = math.random(self.__z_limits[1], self.__z_limits[2])

			local velocity_vector: Vector3 = Vector3.new(x_component, y_component, z_component)
			local projectile_time: number = 0

			local projectile_connection

			trail.Enabled = true

			projectile_connection = RunService.Heartbeat:Connect(function(dt)
				projectile_time += dt
				local current_position: Vector3 = projectile.Position
				local next_position: Vector3 = init_pos
					+ velocity_vector * projectile_time
					+ Vector3.new(0, self.__gravity, 0) * projectile_time * projectile_time
				local travel_direction: Vector3 = next_position - current_position

				local raycast_result: {} = workspace:Raycast(current_position, travel_direction, self.__raycast_params)

				projectile.Position = next_position
				if raycast_result and raycast_result.Instance.Name ~= "Baseplate" then
					return
				end
				if raycast_result or projectile_time > effect_duration then
					projectile_connection:Disconnect()
					total_destroyed += 1

					if raycast_result then
						callback(raycast_result)
					end

					trail.Enabled = false

					trail:Clear()
					self.PartCache:ReturnPart(projectile)
				end
			end)

			task.wait(effect_interval)
		end
	end)

	return
end

function Splatter3D:PrintStats(): nil
	print("---------------------------------")
	print("Total Created: " .. total_projectiles)
	print("Total Destroyed: " .. total_destroyed)
	print("Part Cache Open: " .. self.PartCache:ReturnNumOpen())
	return
end

function Splatter3D.new(
	raycast_params,
	effect_part: Instance,
	x_limits: { number },
	y_limits: { number },
	z_limits: { number },
	gravity: number
): {}
	local self = setmetatable({}, Splatter3D)
	self.Core = _G.Core
	self.Maid = self.Core.Utils.Maid.new()

	self.__raycast_params = raycast_params or RaycastParams.new()
	self.__raycast_params.FilterType = Enum.RaycastFilterType.Exclude

	self.__x_limits = x_limits or { -15, 15 }
	self.__z_limits = z_limits or { -5, 5 }
	self.__y_magnitude = y_limits or { 1, 17 }

	self.__gravity = gravity or -15

	self.__effect_part = effect_part
	effect_part.Anchored = true
	effect_part.Size = Vector3.new(0.5, 0.5, 0.5)
	effect_part.CanCollide = false
	effect_part.CanTouch = false
	effect_part.CanQuery = false
	effect_part.Transparency = 1

	self.PartCache = self.Core.Utils.PartCache.new(effect_part, 50, workspace)
	return self
end

function Splatter3D:Destroy() end

return Splatter3D
