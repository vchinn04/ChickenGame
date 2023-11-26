local Cannon = {}
Cannon.__index = Cannon
local PROJECTILE_VISUALIZE_REMOTE_EVENT: string = "ProjectileVisualize"

function fetch_dir_and_velocity(start_pos, end_pos, a, t)
	return (end_pos - start_pos - 0.5 * a * t ^ 2) / t
end

function get_random_point_on_part(instance)
	local mid_point = instance.Position
	return Vector3.new(
		math.random(mid_point.X - instance.Size.X / 2, mid_point.X + instance.Size.X / 2),
		mid_point.Y,
		math.random(mid_point.Z - instance.Size.Z / 2, mid_point.Z + instance.Size.Z / 2)
	)
end

function Cannon:OnHit(_, raycast_params, segment_velocity): nil
	local client_table = {
		Normal = raycast_params.Normal,
		Material = raycast_params.Material,
		Position = raycast_params.Position,
		Instance = raycast_params.Instance,
	}
	self.Core.Utils.Net:RemoteEvent("ObstacleHit"):FireAllClients(client_table)

	local character: Instance? = raycast_params.Instance:FindFirstAncestorOfClass("Model")
	if not character then
		return
	end

	return
end

function Cannon:Fire(): nil
	local target = get_random_point_on_part(workspace.Pen)
	local dir =
		fetch_dir_and_velocity(self._cannon_object.Barrel.Position, target, self.Core.GRAVITY_VECTOR, math.random(2, 3))
	self.Core.Utils.Net
		:RemoteEvent(PROJECTILE_VISUALIZE_REMOTE_EVENT)
		:FireAllClients(tick(), "Cannon", "Egg", self._cannon_object.Barrel.Position, dir.Unit, dir.Magnitude)

	self._projectile:Fire(self._cannon_object.Barrel.Position, dir.Unit, dir.Magnitude)
	return
end

function Cannon:Destroy(): nil
	self._maid:DoCleaning()

	self._maid = nil
	self = nil

	return
end

function Cannon.new()
	local self = setmetatable({}, Cannon)

	self.Core = _G.Core
	print("NEW CANNON!")
	self._maid = self.Core.Utils.Maid.new()
	self._cannon_object = workspace.Cannon
	print(self._cannon_object, type(self._cannon_object))
	self._projectile = self.Core.DataManager.GetProjectile(
		"Cannon",
		self._cannon_object,
		nil,
		function(caster, raycast_params, segment_velocity)
			self:OnHit(caster, raycast_params, segment_velocity)
		end
	)

	return self
end

return Cannon
