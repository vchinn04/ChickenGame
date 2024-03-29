local Projectile = {}
Projectile.__index = Projectile
--[[
	<description>
		This class is responsible for handling projectiles on server
	</description> 
	
	<API>
		ProjectileObj:Fire(origin: Vector3, direction: Vector3, velocity: number? | Vector3?, acceleration: Vector3?) ---> {}?
			-- Fire projectile 
			origin: Vector3 -- Position of projectile origin
			direction: Vector3 -- direction to fire in
			velocity: number? | Vector3? -- velocity of projectile. Optional. Default is 100
			acceleration: Vector3? -- accelleration of projectile

		ProjectileObj:SetRayShape(ray_type) ---> nil
			-- Update what type of cast is used to simulate projectile 
			ray_type: number? -- nil -> Raycast, 0 -> Blockcast, 1 -> Spherecast

		ProjectileObj:SetFilter(filter) ---> nil
			-- Reset the filter of the raycast params to a new list 
			filter: { Instance } -- List of new instances that are set to RaycastParams filter.

		ProjectileObj:AppendFilter(filter: { Instance }) ---> nil
			-- Append to the filter of the raycast params to a new list 
			filter: { Instance } -- List of new instances that are appended to RaycastParams filter.

		ProjectileObj:Destroy() ---> nil
			-- Cleanup connections and objects of ProjectileObj

		Projectile.new(projectile_id, raycast_params, ray_hit_callback, ray_update_callback, on_terminating_callback, on_pierced_callback) ---> ProjectileObj
			-- Create a new ProjectileObj
			projectile_id: string -- Id for this projectile class instance
			raycast_params: RaycastParams? -- Raycast Parameters for projectile. Optional.
			ray_hit_callback -- On hit callback
			ray_update_callback -- On ray update callback. Optional.
			on_terminating_callback -- On ray terminating callback. Optional.
			on_pierced_callback -- On ray pierced callback. Optional.

		GetProjectile(rojectile_id, raycast_params, ray_hit_callback, ray_update_callback, on_terminating_callback, on_pierced_callback) ---> ProjectileObj
			-- Returns cached ProjectileObj if it exists, else creates a new ProjectileObj
			projectile_id: string -- Id for this projectile class instance
			raycast_params: RaycastParams? -- Raycast Parameters for projectile. Optional.
			ray_hit_callback -- On hit callback
			ray_update_callback -- On ray update callback. Optional.
			on_terminating_callback -- On ray terminating callback. Optional.
			on_pierced_callback -- On ray pierced callback. Optional.
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.ServerTypes)
local DEFAULT_VELOCITY: number = 100
local ProjectileCache: { [string]: types.ProjectileObject } = {}
--*************************************************************************************************--

function Projectile:Fire(
	origin: Vector3,
	direction: Vector3,
	velocity: number? | Vector3?,
	acceleration: Vector3?
): types.ActiveCast
	if not velocity then
		velocity = DEFAULT_VELOCITY
	end

	if acceleration then
		self._caster_behavior.Acceleration = acceleration
	else
		self._caster_behavior.Acceleration = self.Core.GRAVITY_VECTOR
	end

	return self._caster:Fire(origin, direction, velocity, self._caster_behavior)
end

function Projectile:EventHandler(): nil
	if self._ray_update_callback then
		self._maid.LengthChangedConnection = self._caster.LengthChanged:Connect(self._ray_update_callback)
	end

	if self._ray_hit_callback then
		self._maid.RayHitConnection = self._caster.RayHit:Connect(self._ray_hit_callback)
	end

	if self._on_terminating_callback then
		self._maid.CastTerminatingConnection = self._caster.CastTerminating:Connect(self._on_terminating_callback)
	end

	if self._on_pierced_callback then
		self._maid.CastTerminatingConnection = self._caster.RayPierced:Connect(self._on_pierced_callback)
	end

	return
end

function Projectile:SetRayShape(ray_type: number?): nil
	self._caster_behavior.Shapecast = ray_type

	return
end

function Projectile:SetFilter(filter: { Instance }): nil
	self._caster_behavior.RaycastParams.FilterDescendantsInstances = filter
	return
end

function Projectile:AppendFilter(filter: { Instance }): nil
	self._caster_behavior.RaycastParams.FilterDescendantsInstances += filter
	return
end

function Projectile:Destroy(): nil
	ProjectileCache[self._id] = nil

	self._maid:DoCleaning()
	self._maid = nil
	self._id = nil
	self._caster = nil
	self._caster_behavior = nil
	self._ray_update_callback = nil
	self._ray_hit_callback = nil
	self._on_terminating_callback = nil
	self._on_pierced_callback = nil
	self = nil

	return
end

function Projectile.new(
	projectile_id: string,
	raycast_params: RaycastParams?,
	ray_hit_callback: types.CasterHitCallback?,
	ray_update_callback: types.LengthChangedCallback?,
	on_terminating_callback: types.CasterTerminatingCallback?,
	on_pierced_callback: types.CasterPierceCallback?
): types.ProjectileObject
	local self: types.ProjectileObject = setmetatable({} :: types.ProjectileObject, Projectile)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()
	self._id = projectile_id

	self._caster = self.Core.Utils.FastCastRedux.new()
	self._caster_behavior = self.Core.Utils.FastCastRedux.newBehavior()

	-- Setup RaycastParams
	self._caster_behavior.RaycastParams = raycast_params
	if not raycast_params then
		self._caster_behavior.RaycastParams = RaycastParams.new()
		assert(self._caster_behavior.RaycastParams, "")
		self._caster_behavior.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

		self._caster_behavior.RaycastParams.FilterDescendantsInstances = {}
		self._caster_behavior.RaycastParams.CollisionGroup = "Players"
		self._caster_behavior.Acceleration = self.Core.GRAVITY_VECTOR
	end
	-- Setup Callbacks
	self._ray_update_callback = ray_update_callback
	self._ray_hit_callback = ray_hit_callback
	self._on_terminating_callback = on_terminating_callback
	self._on_pierced_callback = on_pierced_callback

	-- Able to pierce if object is transparent or not collidable.
	self._caster_behavior.CanPierceFunction = function(_, result, _)
		if result.Instance.Transparency == 1 then
			return true
		end
		if not result.Instance.CanCollide then
			local result_path = string.split(result.Instance:GetFullName(), ".")
			local model: Instance? = workspace:FindFirstChild(result_path[2])
			local humanoid: Humanoid? = nil
			print(result, model)
			if model then
				humanoid = model:FindFirstChildOfClass("Humanoid")
			end
			print("Pierce : ", humanoid == nil)
			print("Pierce Object: ", result.Instance)
			return humanoid == nil
		end
		return false
	end

	self:EventHandler()

	return self
end

function Projectile.GetProjectile(
	projectile_id: string,
	raycast_params: RaycastParams?,
	ray_hit_callback: types.CasterHitCallback?,
	ray_update_callback: types.LengthChangedCallback?,
	on_terminating_callback: types.CasterTerminatingCallback?,
	on_pierced_callback: types.CasterPierceCallback?
): types.ProjectileObject
	if ProjectileCache[projectile_id] then
		return ProjectileCache[projectile_id]
	end

	local projectile: types.ProjectileObject = Projectile.new(
		projectile_id,
		raycast_params,
		ray_hit_callback,
		ray_update_callback,
		on_terminating_callback,
		on_pierced_callback
	)

	ProjectileCache[projectile_id] = projectile

	return projectile
end

return Projectile
