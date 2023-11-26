local ThrowableMelee = {}
ThrowableMelee.__index = ThrowableMelee

--[[
	<description>
		This class is responsible for handling the throwable melee functionality.
	</description> 
	
	<API>
		ThrowableMeleeObj:GetBlocked(params) ---> nil
			-- Inform the client that player was blocked and play block effects
			params: {} -- Params passed from client

	  	ThrowableMeleeObj:GetParried(params) ---> nil
			-- Inform the client that player was parried and play parry effects and stun player
			params: {} -- Params passed from client

		ThrowableMeleeObj:Attack(params) ---> nil
			-- Attempt to attack hit player.
			params: {} -- Params passed from client
		
		ThrowableMelee:Throw(params: {}) ---> nil
			-- "Throw" the weapon, unequip it, and remove it from player. 
			   there is no visualization done on server. A remote fired to 
			   all clients to visualize it.
			params: {} -- Array of parameters passed from client. 

		ThrowableMeleeObj:Block(params) ---> nil
			-- Set players Block attribute to updated block status
			params: {} -- Params passed from client

		ThrowableMeleeObj:Parry() ---> nil
			-- Set players parry attribute to true for 0.5 seconds 

		ThrowableMeleeObj:GetToolObject() ---> Instance
			-- return the tool object 

		ThrowableMeleeObj:GetId() ---> string
			-- return the tool id 

		ThrowableMeleeObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		ThrowableMeleeObj:Unequip() ---> nil
			-- Disconnect connections 

		ThrowableMeleeObj:Destroy() ---> nil
			-- Cleanup connections and objects of ThrowableMeleeObj

		ThrowableMelee.new(player, player_object, tool_data) ---> ThrowableMeleeObj
			-- Create a new ThrowableMeleeObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
local PROJECTILE_VISUALIZE_REMOTE_EVENT: string = "ProjectileVisualize"

local PARRY_STUN_DURATION: number = 1
local DISTANCE_DEBUFF: number = 0.5
local PARRY_DURATION: number = 0.5
local DEFAULT_DAMAGE: number = 25

local MAX_CHARGE: number = 100
local DEFAULT_VELOCITY: number = 350

--*************************************************************************************************--

function ThrowableMelee:OnHit(_, raycast_params, segment_velocity): nil
	local client_table = {
		Normal = raycast_params.Normal,
		Material = raycast_params.Material,
		Position = raycast_params.Position,
		Instance = raycast_params.Instance,
	}
	self.Core.Utils.Net:RemoteEvent("ObstacleHit"):FireAllClients(client_table)

	local character: Instance? = raycast_params.Instance:FindFirstAncestorOfClass("Model")

	local drop_instance: Instance? = self.Core.InteractionManager.CreateDrop(self._tool_data.Name)

	if drop_instance then
		drop_instance.Parent = workspace

		local land_point: Instance? = self.Core.Utils.UtilityFunctions.FindFirstDescendant(drop_instance, "LandPoint")

		drop_instance:PivotTo(CFrame.new(raycast_params.Position, raycast_params.Position + segment_velocity))

		if land_point then
			local position_shift = raycast_params.Position - land_point.WorldPosition

			drop_instance:PivotTo(
				CFrame.new(raycast_params.Position + position_shift, raycast_params.Position + segment_velocity)
					* CFrame.Angles(math.rad(land_point.Orientation.X), 0, 0)
			)
		end

		self.Core.Utils.UtilityFunctions.AttachObject(raycast_params.Instance, drop_instance)
	end

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

	attacked_player_object:DoDamage(damage_amount, nil, raycast_params.Instance.Name, segment_velocity * 175)
	attacked_player_object:StartBleeding()

	return
end

function ThrowableMelee:GetBlocked(params): nil
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

function ThrowableMelee:GetParried(params): nil
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

function ThrowableMelee:Attack(params): nil
	params = params[1]

	local attacked_player: Player? = self.Core.Players:GetPlayerFromCharacter(params.HitHumanoid.Parent)

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

function ThrowableMelee:Throw(params: {}): nil
	params = params[1]
	local orientation: CFrame, _ = self:GetToolObject():GetBoundingBox()
	local charge_percentage: number = params.Charge

	if not charge_percentage then
		return
	end

	if charge_percentage > MAX_CHARGE then
		charge_percentage = MAX_CHARGE
	end

	charge_percentage /= 100

	local max_velocity: number = DEFAULT_VELOCITY
	if self._tool_data.MaxVelocity then
		max_velocity = self._tool_data.MaxVelocity
	end

	local velocity: number = max_velocity * charge_percentage

	self.Core.Fire("RemoveItem", self._player, self._tool_data.Name)
	self.Core.DataManager.RemoveItem(self._player, "Items/" .. self._tool_data.Id, 1)

	self.Core.Utils.Net:RemoteEvent(PROJECTILE_VISUALIZE_REMOTE_EVENT):FireAllClients(
		tick(),
		self._tool_data.Name,
		self._tool_data.Name,
		orientation.Position,
		params.Direction,
		velocity
	)
	self._projectile:Fire(orientation.Position, params.Direction, velocity)

	return
end

function ThrowableMelee:Block(params): nil
	self._player:SetAttribute("Blocking", params[1])
	return
end

function ThrowableMelee:Parry(): nil
	self._player:SetAttribute("Parry", true)

	if self._parry_promise then
		self._parry_promise:cancel()
	end

	local parry_duration: number = PARRY_DURATION
	if self._tool_data.ParryDuration then
		parry_duration = self._tool_data.ParryDuration
	end

	self._parry_promise = self.Core.Utils.Promise.delay(parry_duration):finally(function()
		self._player:SetAttribute("Parry", false)
	end)

	return
end

function ThrowableMelee:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function ThrowableMelee:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function ThrowableMelee:EventHandler(): nil
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

function ThrowableMelee:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function ThrowableMelee:Unequip(): nil
	self._connection_maid:DoCleaning()

	if self._parry_promise then
		self._parry_promise:cancel()
	end

	self._player:SetAttribute("Blocking", false)
	self._player:SetAttribute("Parry", false)
	self._maid.BaseTool:Unequip()
	return
end

function ThrowableMelee:Destroy(): nil
	if self._parry_promise then
		self._parry_promise:cancel()
	end
	self._player:SetAttribute("Blocking", nil)
	self._player:SetAttribute("Parry", nil)
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()
	self = nil
	return
end

function ThrowableMelee.new(player: Player, player_object: {}, tool_data: {})
	local self = setmetatable({}, ThrowableMelee)
	self.Core = _G.Core

	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object
	self._projectile = player_object:GetProjectile(
		self._tool_data.Name,
		nil,
		function(caster, raycast_params, segment_velocity)
			self:OnHit(caster, raycast_params, segment_velocity)
		end
	)

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)

	self._maid.NetObject = self.Core.Utils.Net.CreateTemp(self.Core.Utils.Maid)

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

return ThrowableMelee
