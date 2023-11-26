local StandardMelee = {}
StandardMelee.__index = StandardMelee

--[[
	<description>
		This class is responsible for handling the standard melee functionality.
	</description> 
	
	<API>
		StandardMeleeObj:GetBlocked(params) ---> nil
			-- Inform the client that player was blocked and play block effects
			params: {} -- Params passed from client

	  	StandardMeleeObj:GetParried(params) ---> nil
			-- Inform the client that player was parried and play parry effects and stun player
			params: {} -- Params passed from client

		StandardMeleeObj:Attack(params) ---> nil
			-- Attempt to attack hit player.
			params: {} -- Params passed from client
			
		StandardMeleeObj:Block(params) ---> nil
			-- Set players Block attribute to updated block status
			params: {} -- Params passed from client

		StandardMeleeObj:Parry() ---> nil
			-- Set players parry attribute to true for 0.5 seconds 

		StandardMeleeObj:GetToolObject() ---> Instance
			-- return the tool object 

		StandardMeleeObj:GetId() ---> string
			-- return the tool id 

		StandardMeleeObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		StandardMeleeObj:Unequip() ---> nil
			-- Disconnect connections 

		StandardMeleeObj:Destroy() ---> nil
			-- Cleanup connections and objects of StandardMeleeObj

		StandardMelee.new(player, player_object, tool_data) ---> StandardMeleeObj
			-- Create a new StandardMeleeObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"

local PARRY_STUN_DURATION: number = 1
local DISTANCE_DEBUFF: number = 0.5
local PARRY_DURATION: number = 1

--*************************************************************************************************--

function StandardMelee:GetBlocked(params): nil
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

function StandardMelee:GetParried(params): nil
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

function StandardMelee:Attack(params): nil
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

	local attacked_player_object: {} = self.Core.DataManager.GetPlayerObject(attacked_player)

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
			print("Distance Hit")
			attacked_player_object:DoDamage(self._tool_data.Damage * DISTANCE_DEBUFF)
		else
			print("Short Hit!")
			attacked_player_object:DoDamage(self._tool_data.Damage)
		end

		attacked_player_object:StartBleeding()

		self.Core.Utils.Net:RemoteEvent("AttackSuccess"):FireClient(self._player, params.HitPart)
	end

	return
end

function StandardMelee:Block(params): nil
	self._player:SetAttribute("Blocking", params[1])
	return
end

function StandardMelee:Parry(): nil
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

function StandardMelee:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function StandardMelee:GetId(): string
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function StandardMelee:EventHandler(): nil
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

function StandardMelee:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function StandardMelee:Unequip(): nil
	self._connection_maid:DoCleaning()

	if self._parry_promise then
		self._parry_promise:cancel()
	end

	self._player:SetAttribute("Blocking", false)
	self._player:SetAttribute("Parry", false)
	self._maid.BaseTool:Unequip()
	return
end

function StandardMelee:Destroy(): nil
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

function StandardMelee.new(player: Player, player_object: {}, tool_data: {})
	local self = setmetatable({}, StandardMelee)
	self.Core = _G.Core

	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

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

return StandardMelee
