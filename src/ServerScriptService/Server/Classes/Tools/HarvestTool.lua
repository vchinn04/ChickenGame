local HarvestTool = {
	Name = "HarvestTool",
}
HarvestTool.__index = HarvestTool
--[[
	<description>
		This class is responsible for handling the standard Harvest tool functionality.
	</description> 
	
	<API>
		HarvestToolObj:ResourceHit() ---> nil
			-- Player server resource hit effects

		HarvestToolObj:GetToolObject() ---> Instance
			-- return the tool object 

		HarvestToolObj:GetId() ---> string?
			-- return the tool id 

		HarvestToolObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		HarvestToolObj:Unequip() ---> nil
			-- Disconnect connections 

		HarvestToolObj:Destroy() ---> nil
			-- Cleanup connections and objects of HarvestToolObj

		HarvestTool.new(player, player_object, tool_data) ---> HarvestToolObj
			-- Create a new HarvestToolObj
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

function HarvestTool:ResourceHit(): nil
	if self._maid._clone_hit_sound then
		self._maid.SoundObject:Play(self._maid._clone_hit_sound)
	end
	return
end

function HarvestTool:EventHandler(): nil
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

function HarvestTool:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function HarvestTool:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function HarvestTool:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function HarvestTool:Unequip(): nil
	self._connection_maid:DoCleaning()
	self._maid.BaseTool:Unequip()
	return
end

function HarvestTool.new(player, player_object, tool_data)
	local self = setmetatable({}, HarvestTool)

	self.Core = _G.Core
	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)

	self._maid.NetObject = self.Core.Utils.Net.CreateTemp(self.Core.Utils.Maid)

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Server.Hit then
			self._maid._clone_hit_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.Hit.Name,
				self._maid.BaseTool:GetTool()
			)
		end
	end

	return self
end

function HarvestTool:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()
	self = nil
	return
end

return HarvestTool
