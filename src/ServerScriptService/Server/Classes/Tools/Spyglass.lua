local Spyglass = {
	Name = "Spyglass",
}
Spyglass.__index = Spyglass
--[[
	<description>
		This class is responsible for handling the standard Spyglass tool functionality.
	</description> 
	
	<API>
		SpyglassObj:GetToolObject() ---> Instance
			-- return the tool object 

		SpyglassObj:GetId() ---> string?
			-- return the tool id 

		SpyglassObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		SpyglassObj:Unequip() ---> nil
			-- Disconnect connections 

		SpyglassObj:Destroy() ---> nil
			-- Cleanup connections and objects of SpyglassObj

		Spyglass.new(player, player_object, tool_data) ---> SpyglassObj
			-- Create a new SpyglassObj
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

function Spyglass:EventHandler(): nil
	return
end

function Spyglass:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function Spyglass:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Spyglass:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function Spyglass:Unequip(): nil
	self._maid.BaseTool:Unequip()
	return
end

function Spyglass:Destroy(): nil
	self._maid:DoCleaning()
	self._maid = nil
	self = nil
	return
end

function Spyglass.new(player, player_object, tool_data)
	local self = setmetatable({}, Spyglass)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)
	end

	return self
end

return Spyglass
