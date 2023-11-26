local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

--[[
	<description>
		This class is responsible for routing to the Projectile class. It creates, stores, and routes to Projectile instances
	</description> 
	
	<API>
		ProjectileManager:Fire(projectile_id: string, origin: Vector3, direction: Vector3, velocity: number? | Vector3?): {}?
			-- Fire projectile 
			origin: Vector3 -- Position of projectile origin
			direction: Vector3 -- direction to fire in
			velocity: number? | Vector3? -- velocity of projectile. Optional. Default is 100

	  	ProjectileManager:CreateProjectile(projectile_id: string, raycast_params, ray_hit_callback, ray_update_callback, on_terminating_callback, on_pierced_callback): {}
			-- Return a projectile instance or create it if doesn't exit.
			raycast_params: RaycastParams? -- Raycast Parameters for projectile. Optional.
			ray_hit_callback -- On hit callback
			ray_update_callback -- On ray update callback. Optional.
			on_terminating_callback -- On ray terminating callback. Optional.
			on_pierced_callback -- On ray pierced callback. Optional.

		ProjectileManagerObj:Destroy() ---> nil
			-- Cleanup and destroy ProjectileManagerObj

		ProjectileManager.new() ---> ProjectileManagerObj
			-- Create a new ProjectileManagerObj
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local ProjectileClass = nil

local PROJECTILE_CLASS_NAME: string = "Projectile"

--*************************************************************************************************--

function ProjectileManager:Fire(
	projectile_id: string,
	origin: Vector3,
	direction: Vector3,
	velocity: number? | Vector3?
): {}?
	local projectile: {}? = self._maid[projectile_id]
	if projectile then
		return self._maid[projectile_id]:Fire(origin, direction, velocity)
	end
	return
end

function ProjectileManager:CreateProjectile(
	projectile_id: string,
	player: Player? | Instance?,
	raycast_params,
	ray_hit_callback,
	ray_update_callback,
	on_terminating_callback,
	on_pierced_callback
): {}
	local projectile: {}? = self._maid[projectile_id]
	print(player, type(player))
	if projectile then
		return self._maid[projectile_id]
	end

	projectile = ProjectileClass.new(
		raycast_params,
		player,
		ray_hit_callback,
		ray_update_callback,
		on_terminating_callback,
		on_pierced_callback
	)
	self._maid[projectile_id] = projectile
	return projectile
end

function ProjectileManager:Destroy()
	self._maid:DoCleaning()
	self._maid = nil
	self = nil
	return
end

function ProjectileManager.new()
	local self = setmetatable({}, ProjectileManager)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	if not ProjectileClass then
		ProjectileClass = self.Core.Classes:WaitForChild(PROJECTILE_CLASS_NAME, 15)
		if ProjectileClass then
			ProjectileClass = require(ProjectileClass)
		end
	end

	return self
end

return ProjectileManager
