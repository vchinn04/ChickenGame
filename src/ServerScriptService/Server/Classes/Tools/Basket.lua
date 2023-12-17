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

function Basket:AddEgg(): string?
	if #self._egg_stack < self._max_eggs then
		table.insert(self._egg_stack, "Egg")

		local object: Accessory = self.Core.Items:FindFirstChild("Egg"):Clone()
		if not object then
			return
		end

		object.CFrame = self._maid.BaseTool:GetTool().Handle["Egg" .. #self._egg_stack].WorldCFrame
			* CFrame.new(Vector3.new(0, object.Size.Y / 2, 0))
		object.Parent = self.Core.Utils.UtilityFunctions.GetTempsFolder(self._maid.BaseTool:GetTool())
		object.Name = "Egg" .. #self._egg_stack
		self.Core.Utils.UtilityFunctions.AttachObject(self._maid.BaseTool:GetTool().Handle, object)
		print("ADDING EGG TO BASKET!")
	end
	return
end

function Basket:ClearEggs()
	print("Clearing Eggs!")
	self._egg_stack = nil
	self._egg_stack = {}
	self.Core.Utils.UtilityFunctions.ClearTempFolder(self._maid.BaseTool:GetTool())
end

function Basket:GetEggs(): string?
	return self._egg_stack
end

function Basket:IsEmpty(): boolean?
	return #self._egg_stack < 1
end

function Basket:IsFull(): boolean?
	return #self._egg_stack >= self._max_eggs
end

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

	self._max_eggs = 1
	self._egg_stack = {}

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
