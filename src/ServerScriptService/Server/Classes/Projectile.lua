local Projectile = {}
Projectile.__index = Projectile

--[[
	<description>
		This class is responsible for handling projectiles on server
	</description> 
	
	<API>
		ProjectileObj:Fire(origin: Vector3, direction: Vector3, velocity: number? | Vector3?) ---> {}?
			-- Fire projectile 
			origin: Vector3 -- Position of projectile origin
			direction: Vector3 -- direction to fire in
			velocity: number? | Vector3? -- velocity of projectile. Optional. Default is 100

		ProjectileObj:Destroy() ---> nil
			-- Cleanup connections and objects of ProjectileObj

		Projectile.new(	raycast_params, ray_hit_callback, ray_update_callback, on_terminating_callback, on_pierced_callback) ---> ProjectileObj
			-- Create a new ProjectileObj
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

local DEFAULT_VELOCITY: number = 100
--*************************************************************************************************--

function Projectile:Fire(origin: Vector3, direction: Vector3, velocity: number? | Vector3?): {}?
	if not velocity then
		velocity = DEFAULT_VELOCITY
	end

	if self._player and not self._player:IsA("Model") then
		self._caster_behavior.RaycastParams.FilterDescendantsInstances = { self._player.Character }
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

function Projectile:Destroy(): nil
	self._maid:DoCleaning()
	self._maid = nil
	return
end

function Projectile.new(
	raycast_params: RaycastParams?,
	player: Player,
	ray_hit_callback,
	ray_update_callback,
	on_terminating_callback,
	on_pierced_callback
): {}
	local self = setmetatable({}, Projectile)
	print(type(player))
	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()
	self._player = player
	self._caster = self.Core.Utils.FastCastRedux.new()
	self._caster_behavior = self.Core.Utils.FastCastRedux.newBehavior()

	-- Setup RaycastParams
	self._caster_behavior.RaycastParams = raycast_params

	if not raycast_params then
		self._caster_behavior.RaycastParams = RaycastParams.new()
		self._caster_behavior.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local filter = {}

		if player then
			if player:IsA("Model") then
				table.insert(filter, player)
			else
				table.insert(filter, player.Character)
			end
		end

		self._caster_behavior.RaycastParams.FilterDescendantsInstances = filter
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

return Projectile
