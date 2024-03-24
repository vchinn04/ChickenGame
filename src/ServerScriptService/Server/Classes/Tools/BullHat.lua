local BullHat = {
	Name = "BullHat",
}
BullHat.__index = BullHat
--[[
	<description>
		This class is responsible for handling the standard BullHat functionality.
	</description> 
	
	<API>
		PlatypusHatObj:HatSkill() ---> nil 
			-- Perform the hat's skill 

		BullHatObj:GetToolObject() ---> Instance
			-- return the tool object 

		BullHatObj:GetId() ---> string?
			-- return the tool id 

		BullHatObj:Destroy() ---> nil
			-- Cleanup connections and objects of BullHatObj

		BullHat.new(player, player_object, tool_data) ---> BullHatObj
			-- Create a new BullHatObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.Parent.ServerTypes)
local BASE_ACCESSORY: types.BaseAccessory = require(script.Parent.Components.BaseAccessory)
local RunService = game:GetService("RunService")
--*************************************************************************************************--

-- function BullHat:FindPlayerObject(part: Instance): types.PlayerObject?
-- 	local result_path = string.split(part:GetFullName(), ".")
-- 	local character: Instance? = workspace:FindFirstChild(result_path[2])
-- 	if not character then
-- 		return nil
-- 	end

-- 	local player: Player? = self.Core.Players:GetPlayerFromCharacter(character)
-- 	if player == nil then
-- 		return nil
-- 	end

-- 	local player_object: types.PlayerObject? = self.Core.DataManager.GetPlayerObject(player)
-- 	if not player_object then
-- 		return nil
-- 	end

-- 	return player_object
-- end

function BullHat:SetActive(status: boolean): nil
	self._active = status
	self:GetToolObject():SetAttribute("IsActive", self._active)
	print("CHARGE PLAYER!")
	-- self.Core.Utils.Net
	-- 	:RemoteEvent("HidePlayer")
	-- 	:FireAllClients(self._active, self._player.Character, self._transparency_cache)
	return
end

function BullHat:HatSkill(): nil
	if self._active then
		print("IS ACTIVE")
		return
	end

	if self._maid.CooldownManager:CheckCooldown("Skill") then
		print("SKILL COOLDOWN")
		return
	end

	print("BULL HAT SKILL")
	self:SetActive(true)
	local alt: boolean = false
	-- local hitbox_cache = setmetatable({}, { __mode = "k" })
	self.OverlapParams.FilterDescendantsInstances = { self._player_object:GetCharacter() }
	local _, size = self._player.Character:GetBoundingBox()

	self._maid.HitboxConnection = RunService.Heartbeat:Connect(function()
		if alt then
			alt = false
			return
		end

		alt = true

		local player_cframe: CFrame = self._player_object:GetCFrame()
		local hitbox_vector_pos: Vector3 = player_cframe.Position + (player_cframe.LookVector * size.Z)
		-- local res2 = workspace:GetPartBoundsInBox(CFrame.new(hitbox_vector_pos), size, self.OverlapParams)

		local players_hit: { Player } =
			self.Core.Utils.SpatialUtils.GetPlayersInBox(CFrame.new(hitbox_vector_pos), size, self.OverlapParams)

		for player in players_hit do
			local player_object: types.PlayerObject? = self.Core.DataManager.GetPlayerObject(player)
			if not player_object then
				continue
			end

			table.insert(self.OverlapParams.FilterDescendantsInstances, 1, player_object:GetCharacter())
			local enemy_player_cframe: CFrame = player_object:GetCFrame()
			local direction = enemy_player_cframe.Position - player_cframe.Position
			player_object:Knockback(0.25, direction)
		end

		-- for _, part in res2 do
		-- 	local player_object = self:FindPlayerObject(part)
		-- 	if not player_object then
		-- 		continue
		-- 	end
		-- 	if hitbox_cache[player_object] then
		-- 		continue
		-- 	end
		-- 	hitbox_cache[player_object] = true
		-- 	table.insert(self.OverlapParams.FilterDescendantsInstances, 1, player_object:GetCharacter())
		-- 	print("FOUND PLAYER THRU: ", part.Name)
		-- 	local enemy_player_cframe: CFrame = player_object:GetCFrame()
		-- 	local direction = enemy_player_cframe.Position - player_cframe.Position
		-- 	player_object:Knockback(0.25, direction)
		-- end
	end)

	self._deactivate_promise = self.Core.Utils.Promise.delay(self._active_duration):andThen(function()
		self._maid.HitboxConnection = nil
		self:SetActive(false)
	end)

	return
end

function BullHat:EventHandler(): nil
	self._connection_maid:GiveTask(
		self.Core.Utils.Net
			:RemoteEvent(`{self._player.UserId}_hat`).OnServerEvent
			:Connect(function(player, event_name, ...)
				if event_name and self[event_name] then
					local params = { ... }
					self[event_name](self, params)
				end
			end)
	)
	return
end

function BullHat:GetToolObject(): Instance
	return self._maid.BaseAccessory:GetTool()
end

function BullHat:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function BullHat:Destroy(): nil
	if self._deactivate_promise then
		self._deactivate_promise:cancel()
	end
	self:SetActive(false)
	self._maid:DoCleaning()
	self._connection_maid:DoCleaning()
	self._connection_maid = nil
	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self._active = nil
	self._deactivate_promise = nil
	self = nil

	return
end

function BullHat.new(player, player_object, tool_data): types.BullHatObject
	local self: types.BullHatObject = setmetatable({} :: types.BullHatObject, BullHat)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object
	self._active = false
	self._active_duration = 0.7

	self._transparency_cache = {}
	for _, part in self._player_object:GetCharacter():GetDescendants() do
		if part:IsA("BasePart") or part:IsA("Decal") then
			self._transparency_cache[part.Name] = part.Transparency
		end
	end
	self._maid.BaseAccessory = BASE_ACCESSORY.new(player, tool_data)
	self._maid.CooldownManager = self.Core.CooldownClass.new({ { "Skill", 7.5 }, { "Steal", 0.5 } })

	self.OverlapParams = OverlapParams.new()
	self.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self.OverlapParams.FilterDescendantsInstances = { self._player_object:GetCharacter() }
	self.OverlapParams.CollisionGroup = "Players"
	self.OverlapParams.BruteForceAllSlow = false
	self.OverlapParams.RespectCanCollide = false

	self:EventHandler()
	return self
end

return BullHat
