local StandardPistol = {}
StandardPistol.__index = StandardPistol

--[[
	<description>
		This class is responsible for handling the standard swod functionality.
	</description> 
	
	<API>
		StandardPistol:StandardFire(params: {}) ---> nil
			-- Fire projectiles. Fires the min(amount existing, amount needed). 
			params: {} -- Array of parameters passed from client. 

		StandardPistol:Reload(status: boolean) ---> nil
			-- Reload the musket. 
			status : boolean -- True: attempt to reload if enough time has passed. False: Update the _reload_start_clock

		StandardPistolObj:GetToolObject() ---> Instance
			-- return the tool object 

		StandardPistolObj:GetId() ---> string
			-- return the tool id 

		StandardPistolObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		StandardPistolObj:Unequip() ---> nil
			-- Disconnect connections 

		StandardPistolObj:Destroy() ---> nil
			-- Cleanup connections and objects of StandardPistolObj

		StandardPistol.new(player, player_object, tool_data) ---> StandardPistolObj
			-- Create a new StandardPistolObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
local MAX_NETWORK_DELAY: number = 15
local DEFAULT_DAMAGE: number = 25
local TAU: number = math.pi * 2
local DEFAULT_AMMUNITION_TYPE: string = "Flintlock"
local MIN_RELOAD_DURATION: number = 3
local PROJECTILE_MODEL_NAME: string = "Bullet"
local PROJECTILE_VISUALIZE_REMOTE_EVENT: string = "ProjectileVisualize"
local BARREL_POINT: string = "BarrelPoint"
--*************************************************************************************************--

function StandardPistol:OnHit(_, raycast_params, segment_velocity): nil
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

	local attacked_player: Player? = self.Core.Players:GetPlayerFromCharacter(character)
	if attacked_player == nil then
		return
	end

	local attacked_player_object: {}? = self.Core.DataManager.GetPlayerObject(attacked_player)
	if not attacked_player_object then
		return
	end

	local damage_amount: number = DEFAULT_DAMAGE
	if self._tool_data.DefaultDamage then
		damage_amount = self._tool_data.DefaultDamage
	end

	if raycast_params.Instance.Name == "Head" and self._tool_data.HeadshotMultiplier then
		damage_amount *= self._tool_data.HeadshotMultiplier
	end

	attacked_player_object:DoDamage(damage_amount, nil, raycast_params.Instance.Name, segment_velocity.Unit * 155)
	attacked_player_object:StartBleeding()

	return
end

function StandardPistol:StandardFire(params: {}): nil
	if self._bullet_count <= 0 then
		return
	end

	params = params[1]
	local origin: Vector3 = nil

	if self._barrel_point then
		origin = self._barrel_point.WorldPosition
	else
		local orientation: CFrame, _ = self:GetToolObject():GetBoundingBox()
		origin = orientation.Position
	end
	local projectile_count: number = math.min(self._bullet_count, self._tool_data.ProjectileAmount)

	local max_spread: number = 0
	if self._tool_data.MaxBulletSpread then
		max_spread = self._tool_data.MaxBulletSpread
	end

	self._bullet_count -= projectile_count
	self.Core.DataManager.UpdateItem(self._player, "Items/" .. self:GetId() .. "/BulletCount", self._bullet_count)

	for i = 1, projectile_count, 1 do
		local velocity: number = self._tool_data.ProjectileVelocity
		local direction_cf: CFrame = CFrame.new(Vector3.new(), params.Direction)
		local direction: Vector3 = direction_cf
			* CFrame.fromOrientation(0, 0, self._random_number_gen:NextNumber(0, TAU))
			* CFrame.fromOrientation(math.rad(self._random_number_gen:NextNumber(0, max_spread)), 0, 0).LookVector

		self.Core.Utils.Net
			:RemoteEvent(PROJECTILE_VISUALIZE_REMOTE_EVENT)
			:FireAllClients(tick(), self._tool_data.Name, PROJECTILE_MODEL_NAME, origin, direction, velocity)

		self._projectile:Fire(origin, direction, velocity)
	end

	return
end

function StandardPistol:Reload(status: boolean): nil
	if self._bullet_count >= self._tool_data.MaxBullets then
		return
	end

	status = status[1]
	if not status then
		self._reload_start_clock = os.clock()
		return
	end

	if not self._reload_start_clock then
		return
	end

	local reload_duration: number = os.clock() - self._reload_start_clock

	if reload_duration < MIN_RELOAD_DURATION or reload_duration >= MAX_NETWORK_DELAY then
		return
	end

	local player_data: {} = self.Core.DataManager.GetPlayerData(self._player)

	local bullet_id: string = self._tool_data.AmmoType
	if not bullet_id then
		bullet_id = DEFAULT_AMMUNITION_TYPE
	end

	local bullet_entry: {} = player_data.Items[bullet_id]
	if not bullet_entry then
		return
	end

	local player_bullet_amount: number = bullet_entry.Amount
	if player_bullet_amount <= 0 then
		return
	end

	local required_bullets: number = self._tool_data.MaxBullets - self._bullet_count
	local reload_amount: number = math.min(required_bullets, player_bullet_amount)

	self._bullet_count += reload_amount

	self.Core.DataManager.RemoveItem(self._player, "Items/" .. bullet_id, reload_amount)
	self.Core.DataManager.UpdateItem(self._player, "Items/" .. self:GetId() .. "/BulletCount", reload_amount)

	return
end

function StandardPistol:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function StandardPistol:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardPistol:EventHandler(): nil
	self._connection_maid:GiveTask(
		self.Core.Utils.Net
			:RemoteEvent(`{self._player.UserId}_tool`).OnServerEvent
			:Connect(function(player, event_name, ...)
				if event_name and self[event_name] then
					local params = { ... }
					self[event_name](self, params)
				end
			end)
	)

	return
end

function StandardPistol:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function StandardPistol:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._maid.BaseTool:Unequip()
	return
end

function StandardPistol:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()
	self = nil
	return
end

function StandardPistol.new(player: Player, player_object: {}, tool_data: {}): {}
	local self = setmetatable({}, StandardPistol)
	self.Core = _G.Core

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object
	self._bullet_count = 0
	self._reload_start_clock = nil
	self._random_number_gen = Random.new()

	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._projectile = player_object:GetProjectile(
		self._tool_data.Name,
		nil,
		function(caster, raycast_params, segment_velocity)
			self:OnHit(caster, raycast_params, segment_velocity)
		end
	)

	local player_data = self.Core.DataManager.GetPlayerData(self._player)
	if player_data then
		local object_data = player_data.Items[tool_data.Id]
		if object_data and object_data.BulletCount then
			self._bullet_count = object_data.BulletCount
		end
	end

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)
	self._maid.NetObject = self.Core.Utils.Net.CreateTemp(self.Core.Utils.Maid)

	self._barrel_point = self.Core.Utils.UtilityFunctions.FindFirstDescendant(self:GetToolObject(), BARREL_POINT)
	if self._tool_data.EffectData then
		self._maid.EffectObject = self.Core.EffectManager.Create(tool_data.EffectPath)

		self._tool_effect_part =
			self.Core.Utils.UtilityFunctions.FindObjectWithPath(self._maid.BaseTool:GetTool(), tool_data.EffectPartPath)
	end

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)
	end

	return self
end

return StandardPistol
