local Compass = {
	Name = "Compass",
}
Compass.__index = Compass
--[[
	<description>
		This class is responsible for handling the standard Compass tool functionality.
	</description> 
	
	<API>
		CompassObj:GetToolObject() ---> Instance
			-- return the tool object 

		CompassObj:GetId() ---> string?
			-- return the tool id 

		CompassObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		CompassObj:Unequip() ---> nil
			-- Disconnect connections 

		CompassObj:Destroy() ---> nil
			-- Cleanup connections and objects of CompassObj

		Compass.new(player, player_object, tool_data) ---> CompassObj
			-- Create a new CompassObj
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

function Compass:EventHandler(): nil
	return
end

function Compass:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function Compass:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Compass:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function Compass:Unequip(): nil
	self._maid.BaseTool:Unequip()
	return
end

function Compass:Destroy(): nil
	self._maid:DoCleaning()

	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function Compass.new(player, player_object, tool_data)
	local self = setmetatable({}, Compass)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)

	if self._tool_data.EffectData then
		self._maid.EffectObject = self.Core.EffectManager.Create(tool_data.EffectPath)

		self._tool_effect_part =
			self.Core.Utils.UtilityFunctions.FindObjectWithPath(self._maid.BaseTool:GetTool(), tool_data.EffectPartPath)
	end

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)
	end

	return self
end

return Compass
