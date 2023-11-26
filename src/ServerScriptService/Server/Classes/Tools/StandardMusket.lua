local StandardMusket = {}
StandardMusket.__index = StandardMusket

--[[
	<description>
		This class is responsible for handling the standard swod functionality.
	</description> 
	
	<API>
		StandardMusketObj:BayonetAttach(params: {}) ---> nil
			-- Attach or detach bayonet from musket. 
			params: {} -- Array of parameters passed from client. 

		StandardMusketObj:StandardFire(params: {}) ---> nil
			-- Fire projectiles. Fires the min(amount existing, amount needed). 
			params: {} -- Array of parameters passed from client. 

		StandardMusketObj:Reload(status: boolean) ---> nil
			-- Reload the musket. 
			status : boolean -- True: attempt to reload if enough time has passed. False: Update the _reload_start_clock

		StandardMusketObj:GetBlocked(params) ---> nil
			-- Inform the client that player was blocked and play block effects
			params: {} -- Params passed from client

	  	StandardMusketObj:GetParried(params) ---> nil
			-- Inform the client that player was parried and play parry effects and stun player
			params: {} -- Params passed from client

		StandardMusketObj:Attack(params) ---> nil
			-- Attempt to attack hit player.
			params: {} -- Params passed from client
			
		StandardMusketObj:Block(params) ---> nil
			-- Set players Block attribute to updated block status
			params: {} -- Params passed from client

		StandardMusketObj:Parry() ---> nil
			-- Set players parry attribute to true for 0.5 seconds 

		StandardMusketObj:GetToolObject() ---> Instance
			-- return the tool object 

		StandardMusketObj:GetId() ---> string
			-- return the tool id 

		StandardMusketObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		StandardMusketObj:Unequip() ---> nil
			-- Disconnect connections 

		StandardMusketObj:Destroy() ---> nil
			-- Cleanup connections and objects of StandardMusketObj

		StandardMusket.new(player, player_object, tool_data) ---> StandardMusketObj
			-- Create a new StandardMusketObj
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
local BAYONET_ID: string = "StandardBayonet"

local PARRY_STUN_DURATION: number = 1
local DISTANCE_DEBUFF: number = 0.5
local BARREL_POINT: string = "BarrelPoint"

--*************************************************************************************************--

function StandardMusket:OnHit(_, raycast_params, segment_velocity): nil
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

	attacked_player_object:DoDamage(damage_amount, nil, raycast_params.Instance.Name, segment_velocity.Unit * 255)
	attacked_player_object:StartBleeding()

	return
end

function StandardMusket:BayonetAttach(params: {}): nil
	local attached_value = params[1]

	if attached_value then
		local player_data: {} = self.Core.DataManager.GetPlayerData(self._player)

		local bayonet_entry: {} = player_data.Items[BAYONET_ID]
		if not bayonet_entry then
			return
		end

		local player_bayonet_amount: number = bayonet_entry.Amount
		if player_bayonet_amount <= 0 then
			return
		end

		self._bayonet_attached = true
		self.Core.DataManager.RemoveItem(self._player, "Items/" .. BAYONET_ID, 1)
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. self:GetId() .. "/BayonetAttached", true)
	else
		self._bayonet_attached = false
		self.Core.DataManager.AddItem(self._player, "Items/" .. BAYONET_ID, 1)
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. self:GetId() .. "/BayonetAttached", false)
	end
	return
end

function StandardMusket:GetBlocked(params: {}): nil
	self.Core.Utils.Net:RemoteEvent("Block"):FireClient(self._player, params.HitPart)

	if self._maid._clone_block_sound then
		self._maid.SoundObject:Play(self._maid._clone_block_sound)
	end

	if self._block_effect_data and self._tool_effect_part then
		self._maid.EffectObject:Emit(
			self._block_effect_data.Name,
			self._tool_effect_part,
			self._block_effect_data.Rate,
			self._block_effect_data.IgnoreAttachment
		)
	end

	return
end

function StandardMusket:GetParried(params: {}): nil
	self._player_object:Stun(PARRY_STUN_DURATION)
	self.Core.Utils.Net:RemoteEvent("Parry"):FireClient(self._player, params.HitPart)

	if self._maid._clone_parry_sound then
		self._maid.SoundObject:Play(self._maid._clone_parry_sound)
	end

	if self._parry_effect_data and self._tool_effect_part then
		self._maid.EffectObject:Emit(
			self._parry_effect_data.Name,
			self._tool_effect_part,
			self._parry_effect_data.Rate,
			self._parry_effect_data.IgnoreAttachment
		)
	end
	return
end

function StandardMusket:Attack(params: {}): nil
	params = params[1]

	local attacked_player: player? = self.Core.Players:GetPlayerFromCharacter(params.HitHumanoid.Parent)

	local character: Model? = params.HitHumanoid.Parent

	if attacked_player == nil then
		if character:GetAttribute("Blocking") then
			self:GetBlocked(params)
			return
		end

		if character:GetAttribute("Parry") then
			self:GetParried(params)
			return
		end

		if self._tool_data.SoundData.Server.DefaultAttack then
			local clone_sound =
				self._maid.SoundObject:CloneSound(self._tool_data.SoundData.Server.DefaultAttack.Name, params.HitPart)
			self._maid.SoundObject:PlayAndDestroy(clone_sound)
		end

		self.Core.Utils.Net:RemoteEvent("AttackSuccess"):FireClient(self._player, params.HitPart)

		return
	end

	local attacked_player_object = self.Core.DataManager.GetPlayerObject(attacked_player)

	if attacked_player:GetAttribute("Blocking") then
		self:GetBlocked(params)
		return
	end

	if attacked_player:GetAttribute("Parry") then
		self:GetParried(params)
		return
	end

	if self._tool_data.SoundData.Server.DefaultAttack then
		local clone_sound =
			self._maid.SoundObject:CloneSound(self._tool_data.SoundData.Server.DefaultAttack.Name, params.HitPart)
		self._maid.SoundObject:PlayAndDestroy(clone_sound)
	end

	if attacked_player_object then
		local attack_distance: Vector3 = (self._player_object:GetPosition() - attacked_player_object:GetPosition()).Magnitude

		if self._tool_data.AttackRange and self._tool_data.AttackRange > attack_distance then
			attacked_player_object:DoDamage(self._tool_data.Damage * DISTANCE_DEBUFF)
		else
			attacked_player_object:DoDamage(self._tool_data.Damage)
		end

		attacked_player_object:StartBleeding()

		self.Core.Utils.Net:RemoteEvent("AttackSuccess"):FireClient(self._player, params.HitPart)
	end

	return
end

function StandardMusket:StandardFire(params: {}): nil
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

function StandardMusket:Reload(status: boolean): nil
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

function StandardMusket:Block(params): nil
	self._player:SetAttribute("Blocking", params[1])
	return
end

function StandardMusket:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function StandardMusket:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardMusket:EventHandler(): nil
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

function StandardMusket:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function StandardMusket:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._maid.BaseTool:Unequip()
	self._player:SetAttribute("Blocking", false)

	return
end

function StandardMusket:Destroy(): nil
	self._player:SetAttribute("Blocking", nil)
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()
	self = nil
	return
end

function StandardMusket.new(player: Player, player_object: {}, tool_data: {})
	local self = setmetatable({}, StandardMusket)
	self.Core = _G.Core

	self._bullet_count = 0
	self._reload_start_clock = nil
	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object
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
		self._block_effect_data = self._tool_data.EffectData.Server.Block
		self._parry_effect_data = self._tool_data.EffectData.Server.Parry

		self._maid.EffectObject = self.Core.EffectManager.Create(tool_data.EffectPath)

		self._tool_effect_part =
			self.Core.Utils.UtilityFunctions.FindObjectWithPath(self._maid.BaseTool:GetTool(), tool_data.EffectPartPath)
	end

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Server.Block then
			self._maid._clone_block_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.Block.Name,
				self._maid.BaseTool:GetTool()
			)
		end

		if self._tool_data.SoundData.Server.Parry then
			self._maid._clone_parry_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.Parry.Name,
				self._maid.BaseTool:GetTool()
			)
		end
	end

	return self
end

return StandardMusket
