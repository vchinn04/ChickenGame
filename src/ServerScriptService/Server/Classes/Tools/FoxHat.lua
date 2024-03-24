local FoxHat = {
	Name = "FoxHat",
}
FoxHat.__index = FoxHat
--[[
	<description>
		This class is responsible for handling the standard FoxHat functionality.
	</description> 
	
	<API>
		FoxHatObj:HatSkill() ---> nil 
			-- Perform the hat's skill 
	
		FoxHatObj:Steal() ---> nil
			-- Attempt to steal egg from player in front 

		FoxHatObj:GetToolObject() ---> Instance
			-- return the tool object 

		FoxHatObj:GetId() ---> string?
			-- return the tool id 

		FoxHatObj:Destroy() ---> nil
			-- Cleanup connections and objects of FoxHatObj

		FoxHat.new(player, player_object, tool_data) ---> FoxHatObj
			-- Create a new FoxHatObj
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
--*************************************************************************************************--

-- function FoxHat:FindPlayerObject(part: Instance): types.PlayerObject?
-- 	local result_path = string.split(part:GetFullName(), ".")
-- 	local character: Instance? = workspace:FindFirstChild(result_path[2])
-- 	if not character then
-- 		return nil
-- 	end

-- 	local player: Player? = self.Core.Players:GetPlayerFromCharacter(character)
-- 	if player == nil then
-- 		return nil
-- 	end

-- 	local player_object: types.PlayerObject = self.Core.DataManager.GetPlayerObject(player)
-- 	if not player_object then
-- 		return nil
-- 	end

-- 	return player_object
-- end

function FoxHat:SetActive(status: boolean): nil
	self._active = status
	self:GetToolObject():SetAttribute("IsActive", self._active)
	self.Core.Utils.Net
		:RemoteEvent("HidePlayer")
		:FireAllClients(self._active, self._player.Character, self._transparency_cache)
	return
end

function FoxHat:HatSkill(): nil
	if self._active then
		print("IS ACTIVE")
		return
	end

	if self._maid.CooldownManager:CheckCooldown("Skill") then
		print("SKILL COOLDOWN")
		return
	end

	print("FOX HAT SKILL")
	self:SetActive(true)
	self._deactivate_promise = self.Core.Utils.Promise.delay(self._active_duration):andThen(function()
		self:SetActive(false)
	end)

	return
end

function FoxHat:Steal(): nil
	if not self._active then
		return
	end

	if self._maid.CooldownManager:CheckCooldown("Steal") then
		print("STEAL COOLDOWN")
		return
	end

	print("FOX HAT STEAL")
	local _, size = self._player.Character:GetBoundingBox()

	self.OverlapParams.FilterDescendantsInstances = { self._player_object:GetCharacter() }
	local player_cframe: CFrame = self._player_object:GetCFrame()
	local hitbox_vector_pos: Vector3 = player_cframe.Position + (player_cframe.LookVector * size.Z)

	local players_hit: { Player } =
		self.Core.Utils.SpatialUtils.GetPlayersInBox(CFrame.new(hitbox_vector_pos), size, self.OverlapParams)

	for player in players_hit do
		local player_object: types.PlayerObject? = self.Core.DataManager.GetPlayerObject(player)
		if not player_object then
			continue
		end

		local eggs = player_object:StealEggs(10)
		if not eggs then
			print("No Eggs!")
			return
		end

		print(eggs)

		for _, egg_id in eggs do
			self._player_object:AddEgg(egg_id)
		end
		return
	end

	-- local res2 = workspace:GetPartBoundsInBox(CFrame.new(hitbox_vector_pos), size, self.OverlapParams)

	-- for _, part in res2 do
	-- 	local player_object = self:FindPlayerObject(part)
	-- 	if not player_object then
	-- 		continue
	-- 	end
	-- 	print("FOUND PLAYER THRU: ", part.Name)
	-- 	local eggs = player_object:StealEggs(10)
	-- 	if not eggs then
	-- 		print("No Eggs!")
	-- 		return
	-- 	end

	-- 	print(eggs)

	-- 	for _, egg_name in eggs do
	-- 		self._player_object:AddEgg()
	-- 	end
	-- 	return
	-- end

	return
end

function FoxHat:EventHandler(): nil
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

function FoxHat:GetToolObject(): Instance
	return self._maid.BaseAccessory:GetTool()
end

function FoxHat:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function FoxHat:Destroy(): nil
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

function FoxHat.new(player, player_object, tool_data): types.FoxHatObject
	local self: types.FoxHatObject = setmetatable({} :: types.FoxHatObject, FoxHat)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self._player = player :: Player
	self._tool_data = tool_data :: types.ToolData
	self._player_object = player_object :: types.PlayerObject
	self._active = false :: boolean
	self._active_duration = 5 :: number

	self._transparency_cache = {} :: { [string]: number }
	for _, part in self._player_object:GetCharacter():GetDescendants() do
		if part:IsA("BasePart") or part:IsA("Decal") then
			self._transparency_cache[part.Name] = part.Transparency
		end
	end
	self._maid.BaseAccessory = BASE_ACCESSORY.new(player, tool_data)
	self._maid.CooldownManager = self.Core.CooldownClass.new({ { "Skill", 7.5 }, { "Steal", 0.5 } })

	self.OverlapParams = OverlapParams.new() :: OverlapParams
	self.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self.OverlapParams.FilterDescendantsInstances = { self._player_object:GetCharacter() }
	self.OverlapParams.CollisionGroup = "Players"
	self.OverlapParams.BruteForceAllSlow = false
	self.OverlapParams.RespectCanCollide = false

	self:EventHandler()
	return self
end

return FoxHat
