local StandardBow = {}
StandardBow.__index = StandardBow

--[[
	<description>
		This class is responsible for handling the standard swod functionality.
	</description> 
	
	<API>
		StandardBowObj:StandardFire(params: {}) ---> nil
			-- Fire projectile and remove it if available.
			params: {} -- Array of parameters passed from client. 

		StandardBowObj:GetToolObject() ---> Instance
			-- return the tool object 

		StandardBowObj:GetId() ---> string
			-- return the tool id 

		StandardBowObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		StandardBowObj:Unequip() ---> nil
			-- Disconnect connections 

		StandardBowObj:Destroy() ---> nil
			-- Cleanup connections and objects of StandardBowObj

		StandardBow.new(player, player_object, tool_data) ---> StandardBowObj
			-- Create a new StandardBowObj
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
local PROJECTILE_MODEL_NAME: string = "Arrow"
local DEFAULT_AMMUNITION_TYPE: string = "Arrow"
local DEFAULT_DAMAGE: number = 25

local MAX_CHARGE: number = 100
local DEFAULT_VELOCITY: number = 350

local BARREL_POINT: string = "BarrelPoint"

--*************************************************************************************************--

function StandardBow:OnHit(_, raycast_params, segment_velocity): nil
	local client_table: {} = {
		Normal = raycast_params.Normal,
		Material = raycast_params.Material,
		Position = raycast_params.Position,
		Instance = raycast_params.Instance,
	}

	local character: Instance? = raycast_params.Instance:FindFirstAncestorOfClass("Model")
	self.Core.Utils.Net:RemoteEvent("ObstacleHit"):FireAllClients(client_table)

	local drop_instance: Instance = self.Core.InteractionManager.CreateDrop(DEFAULT_AMMUNITION_TYPE)
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

	attacked_player_object:DoDamage(damage_amount, nil, raycast_params.Instance.Name, segment_velocity.Unit * 175)
	attacked_player_object:StartBleeding()

	return
end

function StandardBow:StandardFire(params: {}): nil
	params = params[1]

	if not self._arrow_entry then
		local player_data = self.Core.DataManager.GetPlayerData(self._player)
		self._arrow_entry = player_data.Items[DEFAULT_AMMUNITION_TYPE]
	end

	if not self._arrow_entry then
		return
	end

	local player_arrow_amount: number = self._arrow_entry.Amount
	if player_arrow_amount <= 0 then
		return
	end

	local origin: Vector3 = nil
	if self._barrel_point then
		origin = self._barrel_point.WorldPosition
	else
		local orientation: CFrame, _ = self:GetToolObject():GetBoundingBox()
		origin = orientation.Position
	end

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

	self.Core.DataManager.RemoveItem(self._player, "Items/" .. DEFAULT_AMMUNITION_TYPE, 1)

	self.Core.Utils.Net
		:RemoteEvent(PROJECTILE_VISUALIZE_REMOTE_EVENT)
		:FireAllClients(tick(), self._tool_data.Name, PROJECTILE_MODEL_NAME, origin, params.Direction, velocity)
	self._projectile:Fire(origin, params.Direction, velocity)

	return
end

function StandardBow:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function StandardBow:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardBow:EventHandler(): nil
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

function StandardBow:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function StandardBow:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._maid.BaseTool:Unequip()
	return
end

function StandardBow:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()
	self = nil
	return
end

function StandardBow.new(player: Player, player_object: {}, tool_data: {}): {}
	local self = setmetatable({}, StandardBow)
	self.Core = _G.Core

	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._projectile = player_object:GetProjectile("Arrow", nil, function(caster, raycast_params, segment_velocity)
		self:OnHit(caster, raycast_params, segment_velocity)
	end)

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

return StandardBow
