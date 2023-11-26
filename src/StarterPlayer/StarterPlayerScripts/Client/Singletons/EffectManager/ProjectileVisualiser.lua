local ProjectileVisualiser = {}
ProjectileVisualiser.__index = ProjectileVisualiser
--[[
	<description>
		This class is responsible for handling the visualization of projectiles on client. Meant to be used 
		in conjuction with a server cast.
	</description> 
	
	<API>
		ProjectileVisualiser:OnRayUpdated(_, segmentOrigin: Vector3, segmentDirection: Vector3, length: number, _, cosmeticBulletObject: Instance) ---> nil
			-- Default update function for LengthChanged, used to move projectile model.
			segmentOrigin : Vector3 ---> Current location of projectile
            segmentDirection : Vector3 ---> Direction projectile is travelling
			length: number ---> Length of segment travelled
			cosmeticBulletObject: Instance ---> Projectile object
		
		ProjectileVisualiser:Fire(origin: Vector3, direction: Vector3, velocity: number? | Vector3?, network_delay: number?) ---> nil
			-- Fire simulated projectile
            origin : Vector3 -- origin at which to start projectile
            direction : Vector3 -- direction of shot
            velocity : number? | Vector3? -- Velocity of projectile ; Default is 100
			network_delay : number? -- If trigerred by remote event, delay between Server->Client communication. Used to sync.

		ProjectileVisualiserObject:EventHandler() ---> nil
			-- Handle setting up connections to the FastCast instance 

		ProjectileVisualiserObject:Destroy() ---> nil
			-- Destroy ProjectileVisualiser Object

		ProjectileVisualiser.new(raycast_params: RaycastParams, bullet_template: Instance, ray_update_callback: () -> nil) ---> ProjectileVisualiserObject
			-- Create a ProjectileVisualiser instance
			raycast_params : RaycastParams ---> Raycast parameters for projectile
			bullet_template : Instance ---> Template for the visualized projectile 
			ray_update_callback : () -> nil ---> Custom callback that is callef for every LengthChanged event
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local DEFAULT_VELOCITY: number = 100
--*************************************************************************************************--

function ProjectileVisualiser:OnRayUpdated(
	_,
	segmentOrigin: Vector3,
	segmentDirection: Vector3,
	length: number,
	_,
	cosmeticBulletObject: Instance?
): nil
	if cosmeticBulletObject == nil then
		return
	end

	local bulletLength: number = cosmeticBulletObject.Size.Z / 2
	local baseCFrame: CFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))

	return
end

function ProjectileVisualiser:Fire(
	origin: Vector3,
	direction: Vector3,
	velocity: number? | Vector3?,
	network_delay: number?
): nil
	if not velocity then
		velocity = DEFAULT_VELOCITY
	end

	self._caster_behavior.RaycastParams.FilterDescendantsInstances = { self.Core.Character }

	local active_cast = self._caster:Fire(origin, direction, velocity, self._caster_behavior)

	if network_delay then
		if typeof(velocity) == "Vector3" then
			velocity = velocity.Magnitude
		end

		-- active_cast:SetPosition(origin + direction.Unit * velocity * network_delay)
		active_cast:SetVelocity(velocity * direction.Unit) -- + network_delay * active_cast:GetAcceleration()
	end

	return
end

function ProjectileVisualiser:EventHandler(): nil
	self._maid:GiveTask(self._caster.CastTerminating:Connect(function(caster: {})
		local bullet_obj: Instance = caster.RayInfo.CosmeticBulletObject

		if bullet_obj then
			bullet_obj:Destroy()
			bullet_obj = nil
		end

		return
	end))

	if self._ray_update_callback then
		self._maid:GiveTask(self._caster.LengthChanged:Connect(self._ray_update_callback))
	end

	return
end

function ProjectileVisualiser:Destroy(): nil
	self._maid:DoCleaning()
	self._caster_behavior = nil
	self = nil
	return
end

function ProjectileVisualiser.new(
	raycast_params: RaycastParams,
	bullet_template: Instance,
	ray_update_callback: () -> nil
): {}
	local self = setmetatable({}, ProjectileVisualiser)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._caster = self.Core.Utils.FastCastRedux.new()
	self._caster_behavior = self.Core.Utils.FastCastRedux.newBehavior()

	self._caster_behavior.CosmeticBulletTemplate = bullet_template
	self._caster_behavior.CosmeticBulletContainer = self.Core.ProjectileContainer

	self._caster_behavior.AutoIgnoreContainer = true

	self._caster_behavior.RaycastParams = raycast_params

	if not raycast_params then
		self._caster_behavior.RaycastParams = RaycastParams.new()
		self._caster_behavior.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
		self._caster_behavior.RaycastParams.FilterDescendantsInstances = { self.Core.Character }
		self._caster_behavior.RaycastParams.CollisionGroup = "Players"
		self._caster_behavior.Acceleration = self.Core.GRAVITY_VECTOR
	end

	self._ray_update_callback = ray_update_callback
	if not ray_update_callback then
		self._ray_update_callback = function(
			_,
			segmentOrigin: Vector3,
			segmentDirection: Vector3,
			length: number,
			_,
			cosmeticBulletObject: Instance?
		)
			self:OnRayUpdated(nil, segmentOrigin, segmentDirection, length, nil, cosmeticBulletObject)
		end
	end

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
			return humanoid == nil
		end
		return false
	end

	self:EventHandler()
	return self
end

return ProjectileVisualiser
