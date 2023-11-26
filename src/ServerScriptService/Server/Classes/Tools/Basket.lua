local Basket = {
	Name = "Basket",
}
Basket.__index = Basket
--[[
	<description>
		This class is responsible for handling the standard Basket tool functionality.
	</description> 
	
	<API>
		BasketObj:GetToolObject() ---> Instance
			-- return the tool object 

		BasketObj:GetId() ---> string?
			-- return the tool id 

		BasketObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		BasketObj:Unequip() ---> nil
			-- Disconnect connections 

		BasketObj:Destroy() ---> nil
			-- Cleanup connections and objects of BasketObj

		Basket.new(player, player_object, tool_data) ---> BasketObj
			-- Create a new BasketObj
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

function Basket:EventHandler(): nil
	return
end

function Basket:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function Basket:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Basket:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function Basket:Unequip(): nil
	self._maid.BaseTool:Unequip()
	return
end

function Basket:Destroy(): nil
	self._maid:DoCleaning()

	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function Basket.new(player, player_object, tool_data)
	local self = setmetatable({}, Basket)

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

return Basket
