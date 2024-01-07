local FoxHat = {
	Name = "FoxHat",
}
FoxHat.__index = FoxHat
--[[
	<description>
		This class is responsible for handling the standard FoxHat functionality.
	</description> 
	
	<API>
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

local BASE_ACCESSORY_PATH: string = "Tools/BaseAccessory"
--*************************************************************************************************--
local status = false
function FoxHat:HatSkill(): nil
	print("FOX HAT SKILL")
	status = not status
	self.Core.Utils.Net
		:RemoteEvent("HidePlayer")
		:FireAllClients(status, self._player.Character, self._transparency_cache)
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
	self._maid:DoCleaning()
	self._connection_maid:DoCleaning()
	self._connection_maid = nil
	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function FoxHat.new(player, player_object, tool_data)
	local self = setmetatable({}, FoxHat)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object
	self._transparency_cache = {}
	for _, part in self._player.Character:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("Decal") then
			self._transparency_cache[part.Name] = part.Transparency
		end
	end
	self._maid.BaseAccessory = self.Core.Components[BASE_ACCESSORY_PATH].new(player, tool_data)
	self:EventHandler()
	return self
end

return FoxHat
