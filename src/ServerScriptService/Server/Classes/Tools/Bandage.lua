local Bandage = {
	Name = "Bandage",
}
Bandage.__index = Bandage
--[[
	<description>
		This class is responsible for handling the standard Bandage functionality.
	</description> 
	
	<API>
		BandageObj:Trigger() ---> nil
			-- Use bandage

		BandageObj:GetToolObject() ---> Instance
			-- return the tool object 

		BandageObj:GetId() ---> string?
			-- return the tool id 

		BandageObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		BandageObj:Unequip() ---> nil
			-- Disconnect connections 

		BandageObj:Destroy() ---> nil
			-- Cleanup connections and objects of BandageObj

		Bandage.new(player, player_object, tool_data) ---> BandageObj
			-- Create a new BandageObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
--*************************************************************************************************--

function Bandage:Trigger(): nil
	local status: boolean = self._player_object:Heal(self._tool_data.HealAmount)

	if not status then
		return
	end

	self.Core.Fire("RemoveItem", self._player, self._tool_data.Name)
	self.Core.DataManager.RemoveItem(self._player, "Items/" .. self._tool_data.Id, 1)

	self._player_object:CancelBleeding()
	return
end

function Bandage:EventHandler(): nil
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

function Bandage:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function Bandage:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Bandage:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function Bandage:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._maid.BaseTool:Unequip()
	return
end

function Bandage:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()

	self._connection_maid = nil
	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function Bandage.new(player, player_object, tool_data)
	local self = setmetatable({}, Bandage)

	self.Core = _G.Core
	self._toggled = false

	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Server.Trigger then
			self._maid._trigger_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.Trigger.Name,
				self._maid.BaseTool:GetTool()
			)
		end
	end

	return self
end

return Bandage
