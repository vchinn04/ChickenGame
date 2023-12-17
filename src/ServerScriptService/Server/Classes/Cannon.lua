local Cannon = {}
Cannon.__index = Cannon
local PROJECTILE_VISUALIZE_REMOTE_EVENT: string = "ProjectileVisualize"
local TimedFunction

function fetch_dir_and_velocity(start_pos, end_pos, a, t)
	return (end_pos - start_pos - 0.5 * a * t ^ 2) / t
end

function get_random_point_on_part(instance)
	local mid_point = instance.Position
	return Vector3.new(
		math.random(mid_point.X - instance.Size.X / 2, mid_point.X + instance.Size.X / 2),
		mid_point.Y + instance.Size.Y / 2,
		math.random(mid_point.Z - instance.Size.Z / 2, mid_point.Z + instance.Size.Z / 2)
	)
end

function Cannon:OnHit(_, raycast_params, _): nil
	local client_table = {
		Normal = raycast_params.Normal,
		Material = raycast_params.Material,
		Position = raycast_params.Position,
		Instance = raycast_params.Instance,
	}
	self.Core.Utils.Net:RemoteEvent("ObstacleHit"):FireAllClients(client_table)

	local result_path = string.split(raycast_params.Instance:GetFullName(), ".")
	local character: Instance? = workspace:FindFirstChild(result_path[2])
	if not character then
		return
	end

	local hit_player: Player? = self.Core.Players:GetPlayerFromCharacter(character)
	if hit_player == nil then
		return
	end

	local hit_player_object: {}? = self.Core.DataManager.GetPlayerObject(hit_player)
	if not hit_player_object then
		return
	end

	hit_player_object:AddEgg()

	return
end

function Cannon:Fire(): nil
	local target = get_random_point_on_part(workspace.Pen)
	local down_force = self.Core.GRAVITY_VECTOR
	local dir = fetch_dir_and_velocity(self._cannon_object.Barrel.Position, target, down_force, math.random(5, 7.5))

	-- down_force = down_force * dir.Magnitude / 2
	-- dir *= 1 / 2

	self.Core.Utils.Net:RemoteEvent(PROJECTILE_VISUALIZE_REMOTE_EVENT):FireAllClients(
		tick(),
		"Cannon",
		"Egg",
		self._cannon_object.Barrel.Position,
		dir.Unit,
		dir.Magnitude,
		down_force,
		target
	)

	self._projectile:Fire(self._cannon_object.Barrel.Position, dir.Unit, dir.Magnitude, down_force)
	return
end

function Cannon:Start(): nil
	self._maid.FireObject = TimedFunction.new(4)
	self._maid.FireObject:StartTimer(function()
		for _ = 1, math.random(3, 7), 1 do
			task.wait(0.35)
			self:Fire()
		end
		self:Start()
	end)
	return
end

function Cannon:Stop(): nil
	self._maid.FireObject:CancelTimer()
	return
end

function Cannon:Destroy(): nil
	self._maid:DoCleaning()
	self._maid = nil
	self = nil

	return
end

function Cannon.new(interval: number, launch_amount: { number })
	local self = setmetatable({}, Cannon)

	self.Core = _G.Core

	if not TimedFunction then
		TimedFunction = require(self.Core.Classes.TimedFunction)
	end

	self._maid = self.Core.Utils.Maid.new()
	self._cannon_object = workspace.Cannon

	self._interval = interval
	self._launch_amount = launch_amount

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
